ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS edit_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.listings
  ALTER COLUMN edit_count SET DEFAULT 0;
UPDATE public.listings SET edit_count = 0 WHERE edit_count IS NULL;
ALTER TABLE public.listings
  ALTER COLUMN edit_count SET NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.listings'::regclass
      AND conname = 'listings_edit_count_check'
  ) THEN
    ALTER TABLE public.listings
      ADD CONSTRAINT listings_edit_count_check CHECK (edit_count >= 0);
  END IF;
END;
$$;

ALTER TABLE public.listings
  DROP CONSTRAINT IF EXISTS listings_status_check;
ALTER TABLE public.listings
  ADD CONSTRAINT listings_status_check
    CHECK (status IN ('active', 'paused', 'sold', 'removed', 'closed'));

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'offer',
  ADD COLUMN IF NOT EXISTS edit_count integer NOT NULL DEFAULT 0;
ALTER TABLE public.orders
  ALTER COLUMN type SET DEFAULT 'offer',
  ALTER COLUMN edit_count SET DEFAULT 0;
UPDATE public.orders SET type = 'offer' WHERE type IS NULL;
UPDATE public.orders SET edit_count = 0 WHERE edit_count IS NULL;
ALTER TABLE public.orders
  ALTER COLUMN type SET NOT NULL,
  ALTER COLUMN edit_count SET NOT NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.orders'::regclass
      AND conname = 'orders_type_check'
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_type_check
        CHECK (type IN ('offer', 'order', 'contact_request'));
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.orders'::regclass
      AND conname = 'orders_edit_count_check'
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_edit_count_check CHECK (edit_count >= 0);
  END IF;
END;
$$;

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders
  ADD CONSTRAINT orders_status_check
    CHECK (status IN (
      'negotiating', 'agreed', 'accepted', 'declined',
      'completed', 'cancelled'
    ));

CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  profile.id,
  CASE WHEN profile.is_anonymous THEN NULL ELSE profile.full_name END AS full_name,
  profile.avatar_url,
  profile.bio,
  profile.district_id,
  profile.subcounty_id,
  profile.parish_id,
  profile.is_anonymous,
  profile.is_verified,
  profile.created_at,
  profile.role,
  profile.account_type,
  EXISTS (
    SELECT 1
    FROM auth.users AS auth_user
    WHERE auth_user.id = profile.id
      AND NULLIF(BTRIM(auth_user.email), '') IS NOT NULL
  ) AS has_email
FROM public.profiles AS profile;

CREATE OR REPLACE FUNCTION public.enforce_listing_edit_limit()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  details_changed boolean;
BEGIN
  IF actor IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.edit_count IS DISTINCT FROM OLD.edit_count THEN
    RAISE EXCEPTION 'Listing edit count is managed by the database'
      USING ERRCODE = '42501';
  END IF;

  IF OLD.status = 'closed' AND NEW.status <> 'closed' THEN
    RAISE EXCEPTION 'A closed listing cannot be reopened'
      USING ERRCODE = '42501';
  END IF;

  details_changed :=
       NEW.category_id IS DISTINCT FROM OLD.category_id
    OR NEW.title IS DISTINCT FROM OLD.title
    OR NEW.description IS DISTINCT FROM OLD.description
    OR NEW.price_ugx IS DISTINCT FROM OLD.price_ugx
    OR NEW.is_negotiable IS DISTINCT FROM OLD.is_negotiable
    OR NEW.quantity IS DISTINCT FROM OLD.quantity
    OR NEW.unit IS DISTINCT FROM OLD.unit
    OR NEW.remaining_quantity IS DISTINCT FROM OLD.remaining_quantity
    OR NEW.sale_status IS DISTINCT FROM OLD.sale_status
    OR NEW.district_id IS DISTINCT FROM OLD.district_id
    OR NEW.subcounty_id IS DISTINCT FROM OLD.subcounty_id
    OR NEW.parish_id IS DISTINCT FROM OLD.parish_id;

  IF details_changed AND actor = OLD.user_id THEN
    IF OLD.edit_count >= 1 THEN
      RAISE EXCEPTION 'You can only edit a listing once'
        USING ERRCODE = '42501';
    END IF;
    NEW.edit_count := OLD.edit_count + 1;
  END IF;

  IF NEW.status IS DISTINCT FROM OLD.status
     AND NEW.status = 'closed'
     AND actor <> OLD.user_id THEN
    RAISE EXCEPTION 'Only the listing owner can close this listing'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS listings_enforce_edit_limit ON public.listings;
CREATE TRIGGER listings_enforce_edit_limit
  BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION public.enforce_listing_edit_limit();

CREATE OR REPLACE FUNCTION public.protect_order_updates()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
  seller_changed_order boolean;
  is_contact_reveal boolean;
BEGIN
  IF actor IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.listing_id IS DISTINCT FROM OLD.listing_id
     OR NEW.buyer_id IS DISTINCT FROM OLD.buyer_id
     OR NEW.seller_id IS DISTINCT FROM OLD.seller_id
     OR NEW.type IS DISTINCT FROM OLD.type THEN
    RAISE EXCEPTION 'Order participants and type cannot be changed'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.edit_count IS DISTINCT FROM OLD.edit_count THEN
    RAISE EXCEPTION 'Order edit count is managed by the database'
      USING ERRCODE = '42501';
  END IF;

  is_contact_reveal :=
    actor = OLD.seller_id
    AND OLD.type = 'contact_request'
    AND OLD.status = 'negotiating'
    AND NEW.status = 'accepted'
    AND OLD.phone_revealed_by_seller = false
    AND NEW.phone_revealed_by_seller = true
    AND NEW.agreed_price_ugx IS NOT DISTINCT FROM OLD.agreed_price_ugx
    AND NEW.agreed_quantity IS NOT DISTINCT FROM OLD.agreed_quantity
    AND NEW.notes IS NOT DISTINCT FROM OLD.notes;

  IF is_contact_reveal THEN
    IF OLD.edit_count >= 1 THEN
      RAISE EXCEPTION 'This order has already been updated'
        USING ERRCODE = '42501';
    END IF;
    NEW.edit_count := OLD.edit_count + 1;
    RETURN NEW;
  END IF;

  IF NEW.phone_revealed_by_seller IS DISTINCT FROM OLD.phone_revealed_by_seller THEN
    RAISE EXCEPTION 'Contact details can only be revealed by accepting a contact request'
      USING ERRCODE = '42501';
  END IF;

  seller_changed_order :=
    NEW.status IS DISTINCT FROM OLD.status
    OR NEW.agreed_price_ugx IS DISTINCT FROM OLD.agreed_price_ugx
    OR NEW.agreed_quantity IS DISTINCT FROM OLD.agreed_quantity
    OR NEW.notes IS DISTINCT FROM OLD.notes;

  IF actor = OLD.seller_id AND seller_changed_order THEN
    IF OLD.edit_count >= 1
       OR OLD.status NOT IN ('negotiating', 'agreed') THEN
      RAISE EXCEPTION 'You can only update an order once'
        USING ERRCODE = '42501';
    END IF;
    IF (NEW.agreed_price_ugx IS DISTINCT FROM OLD.agreed_price_ugx
        OR NEW.agreed_quantity IS DISTINCT FROM OLD.agreed_quantity
        OR NEW.notes IS DISTINCT FROM OLD.notes)
       AND OLD.type <> 'offer' THEN
      RAISE EXCEPTION 'Only offers can be countered'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.status IS DISTINCT FROM OLD.status
       AND NEW.status NOT IN ('accepted', 'declined') THEN
      RAISE EXCEPTION 'This account cannot make that order status change'
        USING ERRCODE = '42501';
    END IF;
    NEW.edit_count := OLD.edit_count + 1;
    RETURN NEW;
  END IF;

  IF NEW.agreed_price_ugx IS DISTINCT FROM OLD.agreed_price_ugx
     OR NEW.agreed_quantity IS DISTINCT FROM OLD.agreed_quantity
     OR NEW.notes IS DISTINCT FROM OLD.notes THEN
    RAISE EXCEPTION 'Only the seller can counter an offer'
      USING ERRCODE = '42501';
  END IF;

  IF actor = OLD.buyer_id
     AND (
       (OLD.status = 'negotiating' AND NEW.status = 'cancelled')
       OR (
         OLD.status = 'negotiating'
         AND NEW.status = 'accepted'
         AND OLD.type = 'offer'
         AND OLD.edit_count > 0
       )
       OR (OLD.status = 'accepted' AND NEW.status IN ('completed', 'cancelled'))
       OR (OLD.status = 'agreed' AND NEW.status IN ('completed', 'cancelled'))
     ) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'This account cannot make that order status change'
    USING ERRCODE = '42501';
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_order_inserts()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  actor uuid := auth.uid();
BEGIN
  IF actor IS NULL OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.buyer_id <> actor
     OR NEW.edit_count <> 0
     OR NEW.phone_revealed_by_seller THEN
    RAISE EXCEPTION 'Orders must be created by the buyer without seller-only fields'
      USING ERRCODE = '42501';
  END IF;

  IF (NEW.type = 'offer' AND NEW.status <> 'negotiating')
     OR (NEW.type = 'order' AND NEW.status <> 'agreed')
     OR (NEW.type = 'contact_request' AND NEW.status <> 'negotiating') THEN
    RAISE EXCEPTION 'Order type and initial status do not match'
      USING ERRCODE = '22023';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS orders_protect_inserts ON public.orders;
CREATE TRIGGER orders_protect_inserts
  BEFORE INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.protect_order_inserts();

CREATE OR REPLACE FUNCTION public.accept_contact_request(p_order_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  requesting_seller uuid := auth.uid();
BEGIN
  IF requesting_seller IS NULL THEN
    RAISE EXCEPTION 'Sign in is required' USING ERRCODE = '42501';
  END IF;

  UPDATE public.orders
  SET status = 'accepted',
      phone_revealed_by_seller = true
  WHERE id = p_order_id
    AND seller_id = requesting_seller
    AND type = 'contact_request'
    AND status = 'negotiating'
    AND phone_revealed_by_seller = false;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'This contact request is no longer available'
      USING ERRCODE = '42501';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_revealed_seller_phone(p_order_id bigint)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  requesting_buyer uuid := auth.uid();
  seller_phone text;
BEGIN
  IF requesting_buyer IS NULL THEN
    RAISE EXCEPTION 'Sign in is required' USING ERRCODE = '42501';
  END IF;

  SELECT profile.phone INTO seller_phone
  FROM public.orders AS order_row
  JOIN public.profiles AS profile ON profile.id = order_row.seller_id
  WHERE order_row.id = p_order_id
    AND order_row.buyer_id = requesting_buyer
    AND order_row.type = 'contact_request'
    AND order_row.status = 'accepted'
    AND order_row.phone_revealed_by_seller = true;

  IF NOT FOUND OR NULLIF(BTRIM(seller_phone), '') IS NULL THEN
    RAISE EXCEPTION 'The seller has not shared a phone number'
      USING ERRCODE = '42501';
  END IF;

  RETURN seller_phone;
END;
$$;

CREATE OR REPLACE FUNCTION public.request_seller_phone_sms(p_order_id bigint)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  requester uuid := auth.uid();
  order_row public.orders%ROWTYPE;
  existing_status text;
BEGIN
  IF requester IS NULL THEN
    RAISE EXCEPTION 'Sign in is required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO order_row
  FROM public.orders
  WHERE id = p_order_id
    AND status = 'accepted'
    AND (
      seller_id = requester
      OR (
        buyer_id = requester
        AND type = 'contact_request'
        AND phone_revealed_by_seller = true
      )
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'A seller must accept before sharing contact details'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS seller
    WHERE seller.id = order_row.seller_id
      AND NULLIF(BTRIM(seller.phone), '') IS NOT NULL
  ) OR NOT EXISTS (
    SELECT 1 FROM public.profiles AS buyer
    WHERE buyer.id = order_row.buyer_id
      AND NULLIF(BTRIM(buyer.phone), '') IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Both users must have a phone number before SMS delivery'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.seller_phone_sms_queue (order_id)
  VALUES (p_order_id)
  ON CONFLICT (order_id) DO NOTHING;

  SELECT status INTO existing_status
  FROM public.seller_phone_sms_queue
  WHERE order_id = p_order_id;

  IF existing_status = 'sent' THEN
    RETURN 'sent';
  END IF;

  UPDATE public.seller_phone_sms_queue
  SET status = 'queued',
      attempts = 0,
      next_attempt_at = pg_catalog.now(),
      claimed_at = NULL,
      last_error = NULL
  WHERE order_id = p_order_id
    AND status = 'failed';

  RETURN 'queued';
END;
$$;

DROP POLICY IF EXISTS "sellers view their phone sms delivery status"
  ON public.seller_phone_sms_queue;
CREATE POLICY "order participants view their phone sms delivery status"
  ON public.seller_phone_sms_queue FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders AS order_row
      WHERE order_row.id = seller_phone_sms_queue.order_id
        AND (
          order_row.seller_id = (SELECT auth.uid())
          OR (
            order_row.buyer_id = (SELECT auth.uid())
            AND order_row.phone_revealed_by_seller = true
          )
        )
    )
  );

REVOKE ALL ON FUNCTION public.accept_contact_request(bigint)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_contact_request(bigint)
  TO authenticated;
REVOKE ALL ON FUNCTION public.get_revealed_seller_phone(bigint)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_revealed_seller_phone(bigint)
  TO authenticated;
REVOKE ALL ON FUNCTION public.request_seller_phone_sms(bigint)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_seller_phone_sms(bigint)
  TO authenticated;
