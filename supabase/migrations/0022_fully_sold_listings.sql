UPDATE public.listings
SET sale_status = 'fully_sold'
WHERE sale_status = 'sold';

ALTER TABLE public.listings
  DROP CONSTRAINT IF EXISTS listings_sale_status_check;

ALTER TABLE public.listings
  ADD CONSTRAINT listings_sale_status_check
  CHECK (sale_status IN ('available', 'partially_sold', 'fully_sold'));

DROP POLICY IF EXISTS "visible listings are readable" ON public.listings;

CREATE POLICY "visible listings are readable"
  ON public.listings FOR SELECT TO anon, authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR (SELECT public.is_admin())
    OR (
      status = 'active'
      AND sale_status <> 'fully_sold'
      AND public.can_view_listing(user_id, privacy)
    )
  );
