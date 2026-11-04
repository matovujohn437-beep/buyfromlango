ALTER TABLE public.messages
  ADD COLUMN forwarded_from bigint REFERENCES public.messages(id) ON DELETE SET NULL;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-media',
  'chat-media',
  false,
  26214400,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'audio/mp4',
    'audio/aac',
    'audio/mpeg',
    'audio/wav',
    'audio/webm'
  ]
)
ON CONFLICT (id) DO UPDATE
SET public = false,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "chat participants read chat media"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-media'
    AND EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      WHERE thread.id = CASE
        WHEN split_part(name, '/', 1) ~ '^[0-9]+$'
          THEN split_part(name, '/', 1)::bigint
        ELSE NULL
      END
      AND (
        thread.buyer_id = (SELECT auth.uid())
        OR thread.seller_id = (SELECT auth.uid())
        OR (SELECT public.is_admin())
      )
    )
  );

CREATE POLICY "participants upload their own chat media"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-media'
    AND split_part(name, '/', 2) = (SELECT auth.uid())::text
    AND EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      WHERE thread.id = CASE
        WHEN split_part(name, '/', 1) ~ '^[0-9]+$'
          THEN split_part(name, '/', 1)::bigint
        ELSE NULL
      END
      AND (
        thread.buyer_id = (SELECT auth.uid())
        OR thread.seller_id = (SELECT auth.uid())
        OR (SELECT public.is_admin())
      )
    )
  );
