import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAIN_MENU = `Welcome to Buy From Lango!
Reply with a number:
1. Market Prices
2. Search/Buy
3. Sell Produce
4. Register
5. Help`;

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  try {
    const { phone, message } = await req.json();

    // 1. ENFORCE INTERNATIONAL FORMAT (+256)
    let formattedPhone = phone.trim();
    if (formattedPhone.startsWith("0")) {
      formattedPhone = "+256" + formattedPhone.substring(1);
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
      .eq("message", message)
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
      message,
    });

    let reply = "";

    // 4. Check if User is Registered
    const { data: userProfile } = await supabase
      .from("profiles")
      .select("id, full_name, phone")
      .eq("phone", formattedPhone)
      .maybeSingle();

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

      if (details.length < 3) {
        reply =
          "Format: REGISTER Name, District, Subcounty\nExample: REGISTER Okello James, Lira, Adyel";
      } else {
        const [fullName, district, subcounty] = details;

        await supabase.from("profiles").upsert({
          phone: formattedPhone,
          full_name: fullName,
          role: "both",
        }, { onConflict: "phone" });

        if (session) {
          await supabase.from("sms_sessions").delete().eq(
            "phone",
            formattedPhone,
          );
        }
        reply =
          `Thank you ${fullName}. You are registered in ${subcounty}, ${district}! Reply 0 for menu.`;
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

          await supabase.from("listings").insert({
            user_id: userProfile.id,
            title: currentData.item,
            quantity: currentData.quantity,
            price_ugx: price,
            status: "active",
            category_id: "crop",
          });

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
              `${i.id}. ${i.title} - ${i.price_ugx} UGX`
            ).join("\n") +
              "\n\nReply BUY [ID] to get seller's phone. Reply 0 for menu."
            : "No items available today. Reply 0 for menu.";
          break;

        case "3": // Sell
          if (isGuest) {
            reply =
              "You must register to sell.\nReply: REGISTER Name, District, Subcounty";
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
            "To register, reply with your details in this format:\nREGISTER Name, District, Subcounty\n\nExample:\nREGISTER Okello James, Lira, Adyel";
          break;

        default:
          if (upperText.startsWith("BUY ")) {
            const listingId = upperText.replace("BUY ", "");
            if (isGuest) {
              reply =
                "You must register to contact sellers.\nReply: REGISTER Name, District, Subcounty";
            } else {
              const { data: listing, error: listingError } = await supabase
                .from("listings")
                .select("id, user_id")
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
                const { error: orderError } = await supabase
                  .from("orders")
                  .insert({
                    listing_id: listing.id,
                    buyer_id: userProfile.id,
                    seller_id: listing.user_id,
                    type: "contact_request",
                    status: "negotiating",
                  });
                if (orderError) throw orderError;

                const { error: smsError } = await supabase.from("sms_log")
                  .insert({
                    direction: "outbound",
                    phone: seller.phone,
                    message:
                      `Buy From Lango: ${userProfile.full_name} wants to buy your item. Reply REVEAL to share your number.`,
                    status: "queued",
                  });
                if (smsError) throw smsError;

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
