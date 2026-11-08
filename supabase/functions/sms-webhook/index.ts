import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { fitOneSms, oneLine } from "./sms_format.ts";

const MAIN_MENU = `Welcome to Buy From Lango!
Reply with a number:
1. Market Prices
2. Search/Buy
3. Sell Produce
4. Register
5. Help`;

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

serve(async (req) => {
  try {
    const gatewayToken = Deno.env.get("SMS_WEBHOOK_TOKEN");
    if (!gatewayToken) {
      return Response.json({ error: "SMS gateway is not configured." }, {
        status: 503,
      });
    }
    const providedToken = req.headers.get("x-sms-gateway-token") ?? "";
    if (!constantTimeEquals(providedToken, gatewayToken)) {
      return new Response("Unauthorized", { status: 401 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("SMS webhook is not configured.");
    }
    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const payload = await req.json();
    const { phone, message } = payload;
    if (
      typeof phone !== "string" || typeof message !== "string" ||
      !phone.trim() || !message.trim()
    ) {
      throw new Error("A phone number and message are required.");
    }

    let formattedPhone = phone.trim();
    if (formattedPhone.startsWith("0")) {
      formattedPhone = "+256" + formattedPhone.substring(1);
    } else if (formattedPhone.startsWith("256")) {
      formattedPhone = "+" + formattedPhone;
    }
    if (!/^\+256[0-9]{9}$/.test(formattedPhone)) {
      throw new Error("The sender phone number is not a valid Ugandan number.");
    }

    const text = message.trim();
    const upperText = text.toUpperCase();

    // 2. DEDUPLICATION CHECK (Prevent processing the same message twice within 60s)
    const sixtySecondsAgo = new Date(Date.now() - 60000).toISOString();
    const { data: recentDuplicate } = await supabase
      .from("sms_log")
      .select("id")
      .eq("direction", "inbound")
      .eq("phone", formattedPhone)
      .eq("message", text)
      .gte("created_at", sixtySecondsAgo)
      .limit(1)
      .maybeSingle();

    if (recentDuplicate) {
      console.log(`Duplicate message ignored from ${formattedPhone}`);
      return new Response(JSON.stringify({ reply: "" }), { status: 200 });
    }

    // 3. Log Inbound Message
    await supabase.from("sms_log").insert({
      direction: "inbound",
      phone: formattedPhone,
      message: text,
    });

    let reply = "";

    // 4. Check if User is Registered
    const { data: userProfile, error: profileError } = await supabase
      .from("profiles")
      .select("id, full_name, phone, is_feature_phone")
      .eq("phone", formattedPhone)
      .maybeSingle();
    if (profileError) throw profileError;

    const isGuest = !userProfile;

    // 5. Check for active session (for step-by-step menus)
    const { data: session } = await supabase
      .from("sms_sessions")
      .select("*")
      .eq("phone", formattedPhone)
      .maybeSingle();

    // 6. Handle Single-Message Registration
    if (upperText.startsWith("REGISTER ")) {
      const details = text.substring(9).split(",").map((part: string) =>
        part.trim()
      );

      if (details.length !== 4) {
        reply =
          "Format: REGISTER Name, District, Subcounty, Parish/Ward\nExample: REGISTER Okello James, Lira, Aromo, Apua";
      } else {
        const [fullName, district, subcounty, parish] = details;
        if (!fullName || !district || !subcounty || !parish) {
          reply =
            "Format: REGISTER Name, District, Subcounty, Parish/Ward\nExample: REGISTER Okello James, Lira, Aromo, Apua";
        } else {
          const normalizeArea = (value: string) => value.trim().toLowerCase();
          const { data: districtRows, error: districtError } = await supabase
            .from("districts")
            .select("id, name")
            .eq("is_active", true);
          if (districtError) throw districtError;
          const districtRecord = districtRows?.find((row) =>
            normalizeArea(row.name) === normalizeArea(district)
          );

          const { data: subcountyRows, error: subcountyError } = districtRecord
            ? await supabase
              .from("subcounties")
              .select("id, name")
              .eq("district_id", districtRecord.id)
              .eq("is_active", true)
            : { data: null, error: null };
          if (subcountyError) throw subcountyError;
          const subcountyRecord = subcountyRows?.find((row) =>
            normalizeArea(row.name) === normalizeArea(subcounty)
          );

          const { data: parishRows, error: parishError } = subcountyRecord
            ? await supabase
              .from("parishes")
              .select("id, name")
              .eq("subcounty_id", subcountyRecord.id)
              .eq("is_active", true)
            : { data: null, error: null };
          if (parishError) throw parishError;
          const parishRecord = parishRows?.find((row) =>
            normalizeArea(row.name) === normalizeArea(parish)
          );

          if (!districtRecord || !subcountyRecord || !parishRecord) {
            reply =
              "District, subcounty, or parish/ward was not found. Enter the correct area names. Example: REGISTER Name, Lira, Aromo, Apua";
          } else {
            let profileId = userProfile?.id;
            if (!profileId) {
              const { data: createdUser, error: createUserError } =
                await supabase.auth.admin.createUser({
                  phone: formattedPhone,
                  phone_confirm: true,
                  user_metadata: { full_name: fullName, feature_phone: true },
                });
              if (createUserError) throw createUserError;
              profileId = createdUser.user.id;
            }

            const { error: saveProfileError } = await supabase
              .from("profiles")
              .upsert({
                id: profileId,
                phone: formattedPhone,
                full_name: fullName,
                role: "both",
                is_feature_phone: true,
                district_id: districtRecord.id,
                subcounty_id: subcountyRecord.id,
                parish_id: parishRecord.id,
              }, { onConflict: "id" });
            if (saveProfileError) throw saveProfileError;

            if (session) {
              await supabase.from("sms_sessions").delete().eq(
                "phone",
                formattedPhone,
              );
            }
            reply =
              `Thank you ${fullName}. Your feature phone is registered in ${parish}, ${subcounty}, ${district}! Reply 0 for menu.`;
          }
        }
      }
    } else if (upperText.startsWith("CHAT ")) {
      const chatReply = text.match(/^CHAT\s+(\d+)\s+([\s\S]+)$/i);
      if (!userProfile || userProfile.is_feature_phone !== true) {
        reply = "This phone is not enabled for chat-by-SMS.";
      } else if (!chatReply) {
        reply = "Reply CHAT <conversation number> <your message>.";
      } else {
        const threadId = Number(chatReply[1]);
        const content = chatReply[2].trim();
        const { data: thread, error: threadError } = await supabase
          .from("chat_threads")
          .select("id, buyer_id, seller_id")
          .eq("id", threadId)
          .maybeSingle();
        if (threadError) throw threadError;

        if (
          !thread ||
          (thread.buyer_id !== userProfile.id &&
            thread.seller_id !== userProfile.id)
        ) {
          reply = "Conversation not found. Reply with the number in the SMS.";
        } else if (!content || content.length > 4000) {
          reply = "Your reply must contain 1 to 4000 characters.";
        } else {
          const { error: messageError } = await supabase.from("messages")
            .insert({
              thread_id: threadId,
              sender_id: userProfile.id,
              content,
              media_type: "text",
              is_sms: true,
            });
          if (messageError) throw messageError;
          reply = "Your reply was sent to the Buy From Lango conversation.";
        }
      }
    } // 7. Handle Phone Reveal
    else if (upperText === "REVEAL") {
      if (isGuest) {
        reply = "You must register to reveal your number.";
      } else {
        const { data: order, error: orderError } = await supabase
          .from("orders")
          .select("id, buyer_id")
          .eq("seller_id", userProfile.id)
          .eq("type", "contact_request")
          .eq("status", "negotiating")
          .eq("phone_revealed_by_seller", false)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();

        if (orderError) throw orderError;
        if (order) {
          const { data: buyer, error: buyerError } = await supabase
            .from("profiles")
            .select("phone")
            .eq("id", order.buyer_id)
            .maybeSingle();
          if (buyerError) throw buyerError;

          const { data: acceptedOrder, error: acceptError } = await supabase
            .from("orders")
            .update({
              status: "accepted",
              phone_revealed_by_seller: true,
            })
            .eq("id", order.id)
            .eq("seller_id", userProfile.id)
            .eq("type", "contact_request")
            .eq("status", "negotiating")
            .eq("phone_revealed_by_seller", false)
            .select("id")
            .maybeSingle();

          if (acceptError) throw acceptError;
          if (!acceptedOrder) {
            reply = "No pending contact requests found. Reply 0 for menu.";
          } else if (!buyer?.phone) {
            reply =
              "Your number is now available to the buyer in the app, but they have no phone number for SMS delivery.";
          } else {
            const { error: smsError } = await supabase.from("sms_log").insert({
              direction: "outbound",
              phone: buyer.phone,
              message:
                `Buy From Lango: The seller shared their number for your request. Call ${userProfile.phone} to discuss the listing.`,
              status: "queued",
              related_user_id: order.buyer_id,
            });
            if (smsError) {
              console.error(
                "Seller contact SMS could not be queued:",
                smsError,
              );
              reply =
                "Your number is now available to the buyer in the app, but the SMS could not be queued.";
            } else {
              reply =
                "Success! Your number has been sent to the buyer. Reply 0 for menu.";
            }
          }
        } else {
          reply = "No pending contact requests found. Reply 0 for menu.";
        }
      }
    } // 8. Global Commands (Reset Session)
    else if (
      upperText === "HELP" || upperText === "HI" || upperText === "MENU" ||
      upperText === "0"
    ) {
      if (session) {
        await supabase.from("sms_sessions").delete().eq(
          "phone",
          formattedPhone,
        );
      }
      reply = MAIN_MENU;
    } // 9. Handle Active Sessions (Sell Flow)
    else if (session) {
      const currentData = session.temp_data || {};

      if (session.current_flow === "sell" && !isGuest) {
        if (session.step === 1) {
          await supabase.from("sms_sessions").update({
            step: 2,
            temp_data: { ...currentData, item: text },
          }).eq("phone", formattedPhone);
          reply = `How many KG/Bags of ${text} do you have?`;
        } else if (session.step === 2) {
          await supabase.from("sms_sessions").update({
            step: 3,
            temp_data: { ...currentData, quantity: text },
          }).eq("phone", formattedPhone);
          reply = `What is the price per KG/Bag in UGX?`;
        } else if (session.step === 3) {
          const price = parseInt(text) || 0;

          const { error: listingError } = await supabase.from("listings")
            .insert({
              user_id: userProfile.id,
              title: currentData.item,
              quantity: currentData.quantity,
              price_ugx: price,
              status: "active",
              category_id: "crops",
            });
          if (listingError) throw listingError;

          await supabase.from("sms_sessions").delete().eq(
            "phone",
            formattedPhone,
          );
          reply =
            `Success! ${currentData.quantity} of ${currentData.item} listed at ${price} UGX. Buyers will call you. Reply 0 for menu.`;
        }
      }
    } // 10. Handle Top-Level Menu Inputs
    else {
      switch (upperText) {
        case "1": // Prices
          const { data: prices, error: pricesError } = await supabase
            .from("market_prices")
            .select("crop_name, price_per_kg_ugx, retail_price_ugx")
            .limit(3);
          if (pricesError) throw pricesError;
          reply = prices && prices.length > 0
            ? "Today's Prices:\n" + prices.map((price) => {
              const pricePerKg = price.price_per_kg_ugx ??
                price.retail_price_ugx;
              return `${price.crop_name}: ${
                pricePerKg ?? "Price not recorded"
              } UGX`;
            }).join("\n") + "\n\nReply 0 for menu."
            : "Price board is currently updating. Reply 0 for menu.";
          break;

        case "2": // Search/Buy
          const { data: items } = await supabase.from("listings").select(
            "id, title, price_ugx",
          ).eq("status", "active").limit(3);
          reply = items && items.length > 0
            ? "Latest Items:\n" + items.map((i) =>
              `${i.id}. ${oneLine(i.title)} - ${i.price_ugx} UGX`
            ).join("\n") +
              "\n\nReply BUY [ID] to get seller's phone. Reply 0 for menu."
            : "No items available today. Reply 0 for menu.";
          break;

        case "3": // Sell
          if (isGuest) {
            reply =
              "You must register to sell. Reply: REGISTER Name, District, Subcounty, Parish/Ward";
          } else {
            await supabase.from("sms_sessions").upsert({
              phone: formattedPhone,
              current_flow: "sell",
              step: 1,
              temp_data: {},
            });
            reply = "What are you selling? (e.g., Maize, Beans, Goats)";
          }
          break;

        case "4": // Register
          reply =
            "To register, reply: REGISTER Name, District, Subcounty, Parish/Ward\nExample: REGISTER Okello James, Lira, Aromo, Apua";
          break;

        default:
          if (upperText.startsWith("BUY ")) {
            const listingId = upperText.replace("BUY ", "");
            if (isGuest) {
              reply =
                "You must register to contact sellers. Reply: REGISTER Name, District, Subcounty, Parish/Ward";
            } else {
              const { data: listing, error: listingError } = await supabase
                .from("listings")
                .select("id, user_id, title")
                .eq("id", listingId)
                .eq("status", "active")
                .maybeSingle();
              if (listingError) throw listingError;

              const { data: seller, error: sellerError } = listing
                ? await supabase
                  .from("profiles")
                  .select("phone")
                  .eq("id", listing.user_id)
                  .maybeSingle()
                : { data: null, error: null };
              if (sellerError) throw sellerError;

              if (listing && seller?.phone) {
                const { data: existingOrder, error: existingOrderError } =
                  await supabase
                    .from("orders")
                    .select("id")
                    .eq("listing_id", listing.id)
                    .eq("buyer_id", userProfile.id)
                    .eq("seller_id", listing.user_id)
                    .eq("type", "contact_request")
                    .eq("status", "negotiating")
                    .order("created_at", { ascending: false })
                    .limit(1)
                    .maybeSingle();
                if (existingOrderError) throw existingOrderError;

                let orderId = existingOrder?.id;
                if (orderId === undefined) {
                  const { data: order, error: orderError } = await supabase
                    .from("orders")
                    .insert({
                      listing_id: listing.id,
                      buyer_id: userProfile.id,
                      seller_id: listing.user_id,
                      type: "contact_request",
                      status: "negotiating",
                    })
                    .select("id")
                    .single();
                  if (orderError || !order) throw orderError;
                  orderId = order.id;
                }

                const { data: existingNotification, error: notificationError } =
                  await supabase
                    .from("sms_log")
                    .select("id")
                    .eq("related_order_id", orderId)
                    .eq("direction", "outbound")
                    .maybeSingle();
                if (notificationError) throw notificationError;

                if (!existingNotification) {
                  const buyerName = userProfile.full_name?.trim() || "A buyer";
                  const { error: smsError } = await supabase.from("sms_log")
                    .insert({
                      direction: "outbound",
                      phone: seller.phone,
                      message:
                        `Buy From Lango: ${buyerName} has requested your contact for ${listing.title}. Reply REVEAL to share your number.`,
                      status: "queued",
                      related_user_id: listing.user_id,
                      related_order_id: orderId,
                    });
                  if (smsError) throw smsError;
                }

                reply =
                  `Request sent to seller. They have been notified via SMS. Their number will be shared after they accept. Reply 0 for menu.`;
              } else {
                reply =
                  "Item not found or seller unavailable. Reply 0 for menu.";
              }
            }
          } else {
            reply = "Invalid choice. " + MAIN_MENU;
          }
      }
    }

    reply = fitOneSms(reply);

    // 11. Log Outbound Message
    if (reply) {
      await supabase.from("sms_log").insert({
        direction: "outbound",
        phone: formattedPhone,
        message: reply,
        status: "sent",
      });
    }

    return new Response(JSON.stringify({ reply }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(error);
    return new Response(
      JSON.stringify({ reply: "System error. Please try again later." }),
      { status: 200 },
    );
  }
});
