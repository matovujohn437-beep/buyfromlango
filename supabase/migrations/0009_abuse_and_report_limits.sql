CREATE OR REPLACE FUNCTION public.enforce_marketplace_submission_limits()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  actor_id uuid := auth.uid();
BEGIN
  IF actor_id IS NULL THEN
    RETURN NEW;
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(actor_id::text, 0)
  );

  IF TG_TABLE_NAME = 'profiles' THEN
    IF NEW.id <> actor_id AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Profile owner must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.full_name IS NOT NULL
       AND pg_catalog.length(NEW.full_name) > 120 THEN
      RAISE EXCEPTION 'Full name must be 120 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.phone IS NOT NULL AND pg_catalog.length(NEW.phone) > 32 THEN
      RAISE EXCEPTION 'Phone number must be 32 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.bio IS NOT NULL AND pg_catalog.length(NEW.bio) > 1000 THEN
      RAISE EXCEPTION 'Profile bio must be 1000 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.avatar_url IS NOT NULL
       AND pg_catalog.length(NEW.avatar_url) > 2048 THEN
      RAISE EXCEPTION 'Avatar URL is too long'
        USING ERRCODE = '22023';
    END IF;
  ELSIF TG_TABLE_NAME = 'listings' THEN
    IF NEW.user_id <> actor_id THEN
      RAISE EXCEPTION 'Listing owner must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF pg_catalog.length(pg_catalog.btrim(NEW.title)) > 120 THEN
      RAISE EXCEPTION 'Listing title must be 120 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.description IS NOT NULL
       AND pg_catalog.length(NEW.description) > 4000 THEN
      RAISE EXCEPTION 'Listing description must be 4000 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF TG_OP = 'INSERT' AND (
      SELECT pg_catalog.count(*)
      FROM public.listings AS listing
      WHERE listing.user_id = actor_id
        AND listing.created_at >= pg_catalog.now() - interval '24 hours'
    ) >= 10 THEN
      RAISE EXCEPTION 'Listing creation limit reached; try again later'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF TG_TABLE_NAME = 'chat_threads' THEN
    IF NEW.buyer_id <> actor_id THEN
      RAISE EXCEPTION 'Thread buyer must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.blocks AS block
      WHERE (block.blocker_id = NEW.buyer_id
             AND block.blocked_user_id = NEW.seller_id)
         OR (block.blocker_id = NEW.seller_id
             AND block.blocked_user_id = NEW.buyer_id)
    ) THEN
      RAISE EXCEPTION 'This conversation is unavailable'
        USING ERRCODE = '42501';
    END IF;
    IF TG_OP = 'INSERT' AND (
      SELECT pg_catalog.count(*)
      FROM public.chat_threads AS thread
      WHERE thread.buyer_id = actor_id
        AND thread.created_at >= pg_catalog.now() - interval '24 hours'
    ) >= 15 THEN
      RAISE EXCEPTION 'Conversation creation limit reached; try again later'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF TG_TABLE_NAME = 'buyer_needs' THEN
    IF NEW.user_id <> actor_id THEN
      RAISE EXCEPTION 'Buyer need owner must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF pg_catalog.length(pg_catalog.btrim(NEW.item_name)) > 120
       OR pg_catalog.length(pg_catalog.btrim(NEW.contact_person)) > 120
       OR pg_catalog.length(pg_catalog.btrim(NEW.contact_phone)) > 32
       OR (NEW.notes IS NOT NULL AND pg_catalog.length(NEW.notes) > 2000) THEN
      RAISE EXCEPTION 'Buyer need fields exceed the allowed length'
        USING ERRCODE = '22023';
    END IF;
    IF TG_OP = 'INSERT' AND (
      SELECT pg_catalog.count(*)
      FROM public.buyer_needs AS need
      WHERE need.user_id = actor_id
        AND need.created_at >= pg_catalog.now() - interval '24 hours'
    ) >= 5 THEN
      RAISE EXCEPTION 'Buyer request limit reached; try again later'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF TG_TABLE_NAME = 'orders' THEN
    IF NEW.buyer_id <> actor_id THEN
      RAISE EXCEPTION 'Order buyer must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF TG_OP = 'INSERT' AND (
      SELECT pg_catalog.count(*)
      FROM public.orders AS order_row
      WHERE order_row.buyer_id = actor_id
        AND order_row.created_at >= pg_catalog.now() - interval '24 hours'
    ) >= 10 THEN
      RAISE EXCEPTION 'Offer limit reached; try again later'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF TG_TABLE_NAME = 'messages' THEN
    IF NEW.sender_id <> actor_id THEN
      RAISE EXCEPTION 'Message sender must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF (NEW.content IS NULL OR pg_catalog.length(pg_catalog.btrim(NEW.content)) = 0)
       AND NEW.media_url IS NULL THEN
      RAISE EXCEPTION 'A message must contain text or media'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.content IS NOT NULL
       AND pg_catalog.length(NEW.content) > 4000 THEN
      RAISE EXCEPTION 'Message must be 4000 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.media_url IS NOT NULL
       AND pg_catalog.length(NEW.media_url) > 2048 THEN
      RAISE EXCEPTION 'Message media reference is too long'
        USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      JOIN public.blocks AS block
        ON (block.blocker_id = thread.buyer_id
            AND block.blocked_user_id = thread.seller_id)
        OR (block.blocker_id = thread.seller_id
            AND block.blocked_user_id = thread.buyer_id)
      WHERE thread.id = NEW.thread_id
    ) THEN
      RAISE EXCEPTION 'This conversation is unavailable'
        USING ERRCODE = '42501';
    END IF;
    IF (
      SELECT pg_catalog.count(*)
      FROM public.messages AS message
      WHERE message.sender_id = actor_id
        AND message.created_at >= pg_catalog.now() - interval '1 minute'
    ) >= 30 THEN
      RAISE EXCEPTION 'Message rate limit reached; try again shortly'
        USING ERRCODE = 'P0001';
    END IF;
  ELSIF TG_TABLE_NAME = 'reports' THEN
    IF NEW.reporter_id <> actor_id THEN
      RAISE EXCEPTION 'Report author must match the signed-in account'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.target_user_id = actor_id THEN
      RAISE EXCEPTION 'You cannot report your own account'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.target_listing_id IS NOT NULL
       AND NOT EXISTS (
         SELECT 1
         FROM public.listings AS listing
         WHERE listing.id = NEW.target_listing_id
           AND (
             NEW.target_user_id IS NULL
             OR listing.user_id = NEW.target_user_id
           )
       ) THEN
      RAISE EXCEPTION 'Reported listing and user must match'
        USING ERRCODE = '22023';
    END IF;
    IF pg_catalog.length(pg_catalog.btrim(NEW.reason)) > 80
       OR pg_catalog.length(pg_catalog.btrim(NEW.reason)) = 0 THEN
      RAISE EXCEPTION 'Report reason must be between 1 and 80 characters'
        USING ERRCODE = '22023';
    END IF;
    IF NEW.details IS NOT NULL
       AND pg_catalog.length(NEW.details) > 1000 THEN
      RAISE EXCEPTION 'Report details must be 1000 characters or fewer'
        USING ERRCODE = '22023';
    END IF;
    IF (
      SELECT pg_catalog.count(*)
      FROM public.reports AS report
      WHERE report.reporter_id = actor_id
        AND report.created_at >= pg_catalog.now() - interval '1 hour'
    ) >= 5 THEN
      RAISE EXCEPTION 'Report rate limit reached; try again later'
        USING ERRCODE = 'P0001';
    END IF;

    NEW.status := 'open';
    NEW.resolved_at := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER limit_profile_input_lengths
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_listing_submissions
  BEFORE INSERT OR UPDATE ON public.listings
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_message_submissions
  BEFORE INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_thread_creation
  BEFORE INSERT ON public.chat_threads
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_buyer_need_submissions
  BEFORE INSERT OR UPDATE ON public.buyer_needs
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_order_submissions
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE TRIGGER limit_user_reports
  BEFORE INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_marketplace_submission_limits();

CREATE INDEX listings_user_created_at_idx
  ON public.listings (user_id, created_at DESC);
CREATE INDEX messages_sender_created_at_idx
  ON public.messages (sender_id, created_at DESC);
CREATE INDEX buyer_needs_user_created_at_idx
  ON public.buyer_needs (user_id, created_at DESC);
CREATE INDEX orders_buyer_created_at_idx
  ON public.orders (buyer_id, created_at DESC);
CREATE INDEX reports_reporter_created_at_idx
  ON public.reports (reporter_id, created_at DESC);

REVOKE ALL ON FUNCTION public.enforce_marketplace_submission_limits()
  FROM PUBLIC, anon, authenticated;
