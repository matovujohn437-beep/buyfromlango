ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS privacy text;

UPDATE public.listings
SET privacy = CASE
  WHEN privacy = 'contacts_only' THEN 'contacts'
  ELSE COALESCE(privacy, 'public')
END;

ALTER TABLE public.listings
  ALTER COLUMN privacy SET DEFAULT 'public',
  ALTER COLUMN privacy SET NOT NULL;

ALTER TABLE public.listings
  DROP CONSTRAINT IF EXISTS listings_privacy_check;

ALTER TABLE public.listings
  ADD CONSTRAINT listings_privacy_check
    CHECK (privacy IN ('public', 'contacts', 'private'));

DROP POLICY "visible listings are readable" ON public.listings;

CREATE OR REPLACE FUNCTION public.can_view_listing(
  owner_id uuid,
  listing_privacy text
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT owner_id = (SELECT auth.uid())
    OR (SELECT public.is_admin())
    OR EXISTS (
      SELECT 1
      FROM public.profiles AS profile
      WHERE profile.id = owner_id
        AND profile.item_visibility <> 'private'
        AND COALESCE(listing_privacy, 'public') <> 'private'
        AND (
          (
            profile.item_visibility = 'public'
            AND COALESCE(listing_privacy, 'public') = 'public'
          )
          OR (
            (profile.item_visibility = 'contacts'
              OR COALESCE(listing_privacy, 'public') = 'contacts')
            AND (SELECT auth.uid()) IS NOT NULL
            AND EXISTS (
              SELECT 1
              FROM public.chat_threads AS thread
              WHERE (thread.buyer_id = (SELECT auth.uid())
                  AND thread.seller_id = owner_id)
                 OR (thread.seller_id = (SELECT auth.uid())
                  AND thread.buyer_id = owner_id)
            )
          )
        )
    );
$$;
REVOKE ALL ON FUNCTION public.can_view_listing(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_listing(uuid, text)
  TO anon, authenticated;

CREATE POLICY "visible listings are readable"
  ON public.listings FOR SELECT TO anon, authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR (SELECT public.is_admin())
    OR (
      status = 'active'
      AND sale_status <> 'sold'
      AND public.can_view_listing(user_id, privacy)
    )
  );
