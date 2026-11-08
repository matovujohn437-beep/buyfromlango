ALTER TABLE public.chat_threads
  ADD COLUMN buyer_deleted_at timestamptz,
  ADD COLUMN seller_deleted_at timestamptz,
  ADD COLUMN buyer_archived_at timestamptz,
  ADD COLUMN seller_archived_at timestamptz;

CREATE OR REPLACE FUNCTION public.delete_chat_for_current_user(
  p_thread_id bigint
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.chat_threads
  SET buyer_deleted_at = now()
  WHERE id = p_thread_id
    AND buyer_id = (SELECT auth.uid());

  IF FOUND THEN
    RETURN;
  END IF;

  UPDATE public.chat_threads
  SET seller_deleted_at = now()
  WHERE id = p_thread_id
    AND seller_id = (SELECT auth.uid());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Chat not found or user is not a participant';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_chat_for_current_user(bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_chat_for_current_user(bigint)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.set_chat_archived_for_current_user(
  p_thread_id bigint,
  p_archived boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.chat_threads
  SET buyer_archived_at = CASE WHEN p_archived THEN now() ELSE NULL END
  WHERE id = p_thread_id
    AND buyer_id = (SELECT auth.uid());

  IF FOUND THEN
    RETURN;
  END IF;

  UPDATE public.chat_threads
  SET seller_archived_at = CASE WHEN p_archived THEN now() ELSE NULL END
  WHERE id = p_thread_id
    AND seller_id = (SELECT auth.uid());

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Chat not found or user is not a participant';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_chat_archived_for_current_user(bigint, boolean)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_chat_archived_for_current_user(bigint, boolean)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.update_thread_last_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.chat_threads
  SET last_message_at = NEW.created_at,
      buyer_deleted_at = NULL,
      seller_deleted_at = NULL,
      buyer_archived_at = NULL,
      seller_archived_at = NULL
  WHERE id = NEW.thread_id;
  RETURN NEW;
END;
$$;