import { createClient } from "npm:@supabase/supabase-js@2";

type SmsJob = {
  queue_id: number;
  order_id: number;
  buyer_id: string;
  seller_id: string;
};

const encoder = new TextEncoder();

function constantTimeEquals(left: string, right: string): boolean {
  const leftBytes = encoder.encode(left);
  const rightBytes = encoder.encode(right);
  if (leftBytes.length !== rightBytes.length) return false;

  let difference = 0;
  for (let index = 0; index < leftBytes.length; index++) {
    difference |= leftBytes[index] ^ rightBytes[index];
  }
  return difference === 0;
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const pollSecret = Deno.env.get("SMS_POLL_SECRET");
  const gatewayUrl = Deno.env.get("SMS_GATEWAY_URL");
  const gatewayToken = Deno.env.get("SMS_GATEWAY_TOKEN");
  if (
    !supabaseUrl || !serviceRoleKey || !pollSecret || !gatewayUrl ||
    !gatewayToken
  ) {
    return Response.json(
      { error: "SMS worker is not fully configured." },
      { status: 503 },
    );
  }

  const authorization = request.headers.get("authorization") ?? "";
  const bearerToken = authorization.startsWith("Bearer ")
    ? authorization.slice("Bearer ".length)
    : "";
  if (
    !constantTimeEquals(bearerToken, serviceRoleKey) ||
    !constantTimeEquals(request.headers.get("x-poll-secret") ?? "", pollSecret)
  ) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: jobs, error: claimError } = await supabase.rpc(
    "claim_seller_phone_sms",
    { p_batch_size: 20 },
  );
  if (claimError) {
    console.error("Could not claim SMS jobs:", claimError.message);
    return Response.json({ error: "Could not claim SMS jobs." }, {
      status: 500,
    });
  }

  let sent = 0;
  let failed = 0;
  for (const job of (jobs ?? []) as SmsJob[]) {
    let succeeded = false;
    let safeError = "SMS delivery failed.";
    try {
      const [
        { data: buyer, error: buyerError },
        { data: seller, error: sellerError },
      ] = await Promise.all([
        supabase.from("profiles").select("phone").eq("id", job.buyer_id)
          .single(),
        supabase.from("profiles").select("phone").eq("id", job.seller_id)
          .single(),
      ]);
      if (buyerError || sellerError || !buyer?.phone || !seller?.phone) {
        throw new Error("A buyer or seller phone number is unavailable.");
      }

      const gatewayResponse = await fetch(gatewayUrl, {
        method: "POST",
        headers: {
          authorization: `Bearer ${gatewayToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          to: buyer.phone,
          message:
            `The seller for your accepted Buy From Lango offer (Order #${job.order_id}) can be reached at ${seller.phone}.`,
        }),
      });
      if (!gatewayResponse.ok) {
        throw new Error(`SMS gateway returned HTTP ${gatewayResponse.status}.`);
      }
      succeeded = true;
    } catch (error) {
      safeError = error instanceof Error ? error.message : safeError;
      console.error(`SMS job ${job.queue_id} failed:`, safeError);
    }

    const { error: finishError } = await supabase.rpc(
      "finish_seller_phone_sms",
      {
        p_queue_id: job.queue_id,
        p_success: succeeded,
        p_error: succeeded ? null : safeError,
      },
    );
    if (finishError) {
      console.error(
        `Could not finalize SMS job ${job.queue_id}:`,
        finishError.message,
      );
      failed++;
    } else if (succeeded) {
      sent++;
    } else {
      failed++;
    }
  }

  return Response.json({ claimed: jobs?.length ?? 0, sent, failed });
});
