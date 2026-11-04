INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'profile-avatars',
  'profile-avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "public can view profile avatars"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'profile-avatars');

CREATE POLICY "users upload their own profile avatars"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'profile-avatars'
    AND split_part(name, '/', 1) = (SELECT auth.uid())::text
  );
