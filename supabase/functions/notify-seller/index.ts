import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  try {
    // Supabase DB Webhooks send the inserted row as 'record'
    const { record } = await req.json()

    // Contact-request messages are queued by the authenticated RPC so the
    // buyer never receives the seller's phone number.
    if (record.type === 'contact_request') {
      return Response.json({ success: true, skipped: true })
    }
    
    // Fetch seller profile and buyer profile
    const [
      { data: seller, error: sellerError },
      { data: buyer, error: buyerError },
      { data: listing, error: listingError },
    ] = await Promise.all([
      supabase.from('profiles').select('phone, full_name').eq('id', record.seller_id).single(),
      supabase.from('profiles').select('phone, full_name').eq('id', record.buyer_id).single(),
      supabase.from('listings').select('title').eq('id', record.listing_id).single(),
    ])

    if (sellerError || buyerError || listingError || !seller || !buyer || !listing) {
      return new Response("Missing order notification data", { status: 400 })
    }

    // Queue an SMS alert for the seller through the configured gateway.
    const actionText = record.type === 'contact_request'
      ? 'requested contact about'
      : record.type === 'order'
      ? 'placed an order for'
      : 'made an offer on'
    const smsMessage = `Buy From Lango: ${buyer.full_name} (${buyer.phone}) ${actionText} your ${listing.title}. Check the app or reply to this SMS for details.`

    // The Android gateway polls this table and sends outbound SMS messages.
    
    const { error: smsInsertError } = await supabase.from('sms_log').insert({
      direction: 'outbound',
      phone: seller.phone,
      message: smsMessage,
      status: 'queued'
    })
    if (smsInsertError) throw smsInsertError

    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: message }), { status: 400 })
  }
})