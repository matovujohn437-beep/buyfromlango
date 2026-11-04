ALTER TABLE public.sms_log
  ADD COLUMN related_order_id bigint
    REFERENCES public.orders(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX sms_log_outbound_order_unique_idx
  ON public.sms_log (related_order_id)
  WHERE direction = 'outbound' AND related_order_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.queue_notification_sms(
  p_order_id bigint,
  p_message text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  requesting_buyer uuid := auth.uid();
  request_row record;
  expected_message text;
  inserted_count integer;
BEGIN
  IF requesting_buyer IS NULL THEN
    RAISE EXCEPTION 'Sign in is required'
      USING ERRCODE = '42501';
  END IF;

  SELECT
    order_row.buyer_id,
    order_row.seller_id,
    order_row.type,
    order_row.status,
    buyer.full_name AS buyer_name,
    seller.phone AS seller_phone,
    listing.title AS listing_title
  INTO request_row
  FROM public.orders AS order_row
  JOIN public.profiles AS buyer ON buyer.id = order_row.buyer_id
  JOIN public.profiles AS seller ON seller.id = order_row.seller_id
  JOIN public.listings AS listing ON listing.id = order_row.listing_id
  WHERE order_row.id = p_order_id
    AND order_row.buyer_id = requesting_buyer
    AND order_row.type = 'contact_request'
    AND order_row.status = 'negotiating';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contact request was not found or is no longer active'
      USING ERRCODE = '42501';
  END IF;

  IF NULLIF(pg_catalog.btrim(request_row.seller_phone), '') IS NULL THEN
    RAISE EXCEPTION 'The poster has not added a phone number'
      USING ERRCODE = '22023';
  END IF;

  expected_message := pg_catalog.format(
    'Buy From Lango: %s has requested your contact for %s. Reply REVEAL to share your number.',
    COALESCE(NULLIF(pg_catalog.btrim(request_row.buyer_name), ''), 'A buyer'),
    request_row.listing_title
  );

  IF p_message IS DISTINCT FROM expected_message THEN
    RAISE EXCEPTION 'Contact request notification message is invalid'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.sms_log (
    direction,
    phone,
    message,
    status,
    related_user_id,
    related_order_id
  )
  VALUES (
    'outbound',
    request_row.seller_phone,
    expected_message,
    'queued',
    request_row.seller_id,
    p_order_id
  )
  ON CONFLICT (related_order_id)
    WHERE direction = 'outbound' AND related_order_id IS NOT NULL
  DO NOTHING;

  GET DIAGNOSTICS inserted_count = ROW_COUNT;
  IF inserted_count = 0 THEN
    RETURN 'already_queued';
  END IF;

  RETURN 'queued';
END;
$$;

REVOKE ALL ON FUNCTION public.queue_notification_sms(bigint, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.queue_notification_sms(bigint, text)
  TO authenticated;
