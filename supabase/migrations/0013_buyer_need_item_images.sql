ALTER TABLE public.buyer_needs
  ADD COLUMN item_image_url text;

CREATE OR REPLACE VIEW public.public_buyer_needs AS
SELECT
  need.id,
  need.user_id,
  need.item_name,
  need.quantity,
  need.unit,
  need.proposed_price_ugx,
  need.notes,
  need.contact_person,
  need.district_id,
  district.name AS district_name,
  need.subcounty_id,
  subcounty.name AS subcounty_name,
  need.parish_id,
  parish.name AS parish_name,
  need.created_at,
  CASE
    WHEN profile.is_anonymous THEN 'Anonymous buyer'
    ELSE COALESCE(NULLIF(profile.full_name, ''), 'Buyer')
  END AS poster_name,
  CASE WHEN profile.is_anonymous THEN NULL ELSE profile.avatar_url END
    AS poster_avatar_url,
  profile.is_verified AS poster_is_verified,
  profile.account_type AS poster_account_type,
  need.item_image_url
FROM public.buyer_needs AS need
JOIN public.districts AS district ON district.id = need.district_id
LEFT JOIN public.subcounties AS subcounty
  ON subcounty.id = need.subcounty_id
LEFT JOIN public.parishes AS parish ON parish.id = need.parish_id
JOIN public.profiles AS profile ON profile.id = need.user_id
WHERE need.status = 'active';

GRANT SELECT ON public.public_buyer_needs TO anon, authenticated;

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'buyer-need-images',
  'buyer-need-images',
  true,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "public can view buyer need images"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'buyer-need-images');

CREATE POLICY "users upload their own buyer need images"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'buyer-need-images'
    AND split_part(name, '/', 1) = (SELECT auth.uid())::text
  );

CREATE POLICY "users delete their own buyer need images"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'buyer-need-images'
    AND split_part(name, '/', 1) = (SELECT auth.uid())::text
  );
