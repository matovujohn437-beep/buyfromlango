ALTER TABLE public.sms_log
  ADD COLUMN IF NOT EXISTS recipient_phone text,
  ADD COLUMN IF NOT EXISTS message_body text,
  ADD COLUMN IF NOT EXISTS type text;

UPDATE public.sms_log
SET recipient_phone = phone,
    message_body = message
WHERE recipient_phone IS NULL
   OR message_body IS NULL;

CREATE INDEX IF NOT EXISTS sms_log_gateway_pending_idx
  ON public.sms_log (created_at)
  WHERE direction = 'outbound' AND status = 'pending';
