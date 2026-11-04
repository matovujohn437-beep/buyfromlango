CREATE TABLE public.chat_message_reactions (
  thread_id bigint NOT NULL REFERENCES public.chat_threads(id) ON DELETE CASCADE,
  message_id bigint NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji text NOT NULL CHECK (emoji IN ('👍', '❤️', '😂', '😮', '😢')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, user_id, emoji)
);

CREATE INDEX chat_message_reactions_thread_idx
  ON public.chat_message_reactions (thread_id, message_id);

ALTER TABLE public.chat_message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "thread participants read message reactions"
  ON public.chat_message_reactions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      WHERE thread.id = chat_message_reactions.thread_id
        AND (
          thread.buyer_id = (SELECT auth.uid())
          OR thread.seller_id = (SELECT auth.uid())
          OR (SELECT public.is_admin())
        )
    )
  );

CREATE POLICY "participants add their own message reactions"
  ON public.chat_message_reactions FOR INSERT TO authenticated
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      JOIN public.messages AS message
        ON message.id = chat_message_reactions.message_id
       AND message.thread_id = thread.id
       AND NOT message.is_deleted
      WHERE thread.id = chat_message_reactions.thread_id
        AND (
          thread.buyer_id = (SELECT auth.uid())
          OR thread.seller_id = (SELECT auth.uid())
        )
    )
  );

CREATE POLICY "users remove their own message reactions"
  ON public.chat_message_reactions FOR DELETE TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.chat_threads AS thread
      WHERE thread.id = chat_message_reactions.thread_id
        AND (
          thread.buyer_id = (SELECT auth.uid())
          OR thread.seller_id = (SELECT auth.uid())
        )
    )
  );

GRANT SELECT, INSERT, DELETE ON public.chat_message_reactions TO authenticated;

ALTER TABLE public.listing_media
  DROP CONSTRAINT IF EXISTS listing_media_media_type_check;
ALTER TABLE public.listing_media
  ADD CONSTRAINT listing_media_media_type_check
  CHECK (media_type IN ('image', 'video', 'audio', 'document'));

UPDATE storage.buckets
SET allowed_mime_types = array_append(allowed_mime_types, 'application/pdf')
WHERE id = 'listing-media'
  AND NOT ('application/pdf' = ANY(allowed_mime_types));

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'chat_message_reactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime
      ADD TABLE public.chat_message_reactions;
  END IF;
END;
$$;
