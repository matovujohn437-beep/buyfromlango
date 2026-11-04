# Chat SMS worker

The worker claims pending chat SMS jobs from `public.sms_queue`, submits them
to the configured SMS gateway, and retries failed deliveries up to five times.
Chat messages and queue rows are created atomically by
`send_chat_text_message`.

Deploy the migration and function:

```powershell
npx supabase db push
npx supabase functions deploy poll-chat-sms
```

Set `SMS_GATEWAY_URL`, `SMS_GATEWAY_TOKEN`, and `SMS_POLL_SECRET` using Supabase
secrets. Schedule a trusted `POST` to the function at a short interval, with
the service-role bearer token and `x-poll-secret` header, as described in the
seller phone SMS worker documentation. The gateway must accept JSON containing
`to` and `message` and return a 2xx response when it accepts the SMS.

Feature-phone recipients can reply with `CHAT <conversation number> <message>`.
Configure the SMS provider's inbound webhook to call the existing
`sms-webhook` function so replies are inserted into `public.messages` and
delivered to the app through Supabase Realtime.

Set `profiles.is_feature_phone` to `true` for opted-in feature-phone accounts
(using an authorized admin or registration flow), and make sure `profiles.phone`
contains the international phone number. The column defaults to `false`; for
example, from an authorized SQL session:

```sql
UPDATE public.profiles
SET is_feature_phone = true
WHERE id = '<profile UUID>'
  AND phone = '+256XXXXXXXXX';
```
