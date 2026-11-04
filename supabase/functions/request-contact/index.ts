import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return Response.json(body, { status, headers: corsHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed." }, 405);
  }

  const authorization = request.headers.get("authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!token) {
    return jsonResponse({ error: "Authentication is required." }, 401);
  }
  if (!supabaseUrl || !serviceRoleKey) {
    console.error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is missing.");
    return jsonResponse(
      { error: "The contact service is not configured." },
      500,
    );
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return jsonResponse({ error: "Authentication is required." }, 401);
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: "A valid JSON body is required." }, 400);
  }
  if (payload === null || typeof payload !== "object") {
    return jsonResponse({ error: "A valid JSON body is required." }, 400);
  }

  const body = payload as Record<string, unknown>;
  const listingId = body.listing_id;
  if (!Number.isSafeInteger(listingId) || (listingId as number) < 1) {
    return jsonResponse({ error: "A valid listing_id is required." }, 400);
  }
  if (body.buyer_id !== undefined && body.buyer_id !== user.id) {
    return jsonResponse(
      { error: "The buyer does not match the session." },
      403,
    );
  }

  const { data: listing, error: listingError } = await supabase
    .from("listings")
    .select("id, title, user_id")
    .eq("id", listingId as number)
    .eq("status", "active")
    .maybeSingle();
  if (listingError) {
    console.error("Could not check listing:", listingError.message);
    return jsonResponse({ error: "The listing could not be checked." }, 500);
  }
  if (!listing) {
    return jsonResponse(
      { error: "The listing was not found or is inactive." },
      404,
    );
  }
  if (listing.user_id === user.id) {
    return jsonResponse(
      { error: "You cannot request your own phone number." },
      400,
    );
  }

  const [
    { data: seller, error: sellerError },
    { data: buyer, error: buyerError },
  ] = await Promise.all([
    supabase
      .from("profiles")
      .select("phone")
      .eq("id", listing.user_id)
      .maybeSingle(),
    supabase
      .from("profiles")
      .select("full_name")
      .eq("id", user.id)
      .maybeSingle(),
  ]);
  if (sellerError || buyerError) {
    console.error("Could not load contact profiles:", {
      sellerError: sellerError?.message,
      buyerError: buyerError?.message,
    });
    return jsonResponse(
      { error: "Contact details could not be checked." },
      500,
    );
  }
  if (!seller?.phone?.trim()) {
    return jsonResponse(
      { error: "The seller has not added a phone number." },
      404,
    );
  }
  const { data: existingOrder, error: existingOrderError } = await supabase
    .from("orders")
    .select("id")
    .eq("listing_id", listing.id)
    .eq("buyer_id", user.id)
    .eq("seller_id", listing.user_id)
    .eq("type", "contact_request")
    .eq("status", "negotiating")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (existingOrderError) {
    console.error(
      "Could not check existing contact requests:",
      existingOrderError.message,
    );
    return jsonResponse(
      { error: "The contact request could not be checked." },
      500,
    );
  }

  let orderId = existingOrder?.id;
  if (orderId === undefined) {
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .insert({
        listing_id: listing.id,
        buyer_id: user.id,
        seller_id: listing.user_id,
        type: "contact_request",
        status: "negotiating",
      })
      .select("id")
      .single();
    if (orderError || !order) {
      console.error("Could not create contact request:", orderError?.message);
      return jsonResponse({
        error: "The contact request could not be created.",
      }, 500);
    }
    orderId = order.id;
  }

  const { data: existingNotification, error: notificationLookupError } =
    await supabase
      .from("sms_log")
      .select("id")
      .eq("related_order_id", orderId)
      .eq("direction", "outbound")
      .maybeSingle();
  if (notificationLookupError) {
    console.error(
      "Could not check seller notification:",
      notificationLookupError.message,
    );
    return jsonResponse({
      error: "The seller notification could not be checked.",
    }, 500);
  }

  if (!existingNotification) {
    const buyerName = buyer?.full_name?.trim() || "A buyer";
    const message =
      `Buy From Lango: ${buyerName} has requested your contact for ${listing.title}. Reply REVEAL to share your number.`;
    const { error: smsError } = await supabase.from("sms_log").insert({
      direction: "outbound",
      phone: seller.phone,
      message,
      status: "queued",
      related_user_id: listing.user_id,
      related_order_id: orderId,
    });
    if (smsError) {
      console.error("Could not queue seller notification:", smsError.message);
      return jsonResponse({
        error: "The seller notification could not be queued.",
      }, 500);
    }
  }

  return jsonResponse({
    success: true,
    message:
      "The seller was notified. Their number will be shared after they accept.",
    order_id: orderId,
  });
});
