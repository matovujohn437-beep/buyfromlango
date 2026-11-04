# Seller phone SMS worker

The worker reads phone numbers with the Supabase service role only after the
seller requests sharing an accepted offer. It sends the seller's number to the
buyer's phone and never returns either phone number to the app.

Deploy it with:

```powershell
npx supabase functions deploy poll-seller-phone-sms
npx supabase secrets set SMS_GATEWAY_URL="https://your-gateway.example/messages" SMS_GATEWAY_TOKEN="..." SMS_POLL_SECRET="..."
```

Configure a scheduled `POST` invocation in Supabase (or another trusted
scheduler) at a short interval, for example every minute. The invocation must
include both:

```text
Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
x-poll-secret: <SMS_POLL_SECRET>
```

The gateway URL must accept a JSON `POST` body with `to` and `message` fields,
authenticate the request using `Authorization: Bearer <SMS_GATEWAY_TOKEN>`, and
return a 2xx response only when the SMS is accepted for delivery. Adapt the
request in `index.ts` if the chosen provider has a different API contract.

The worker processes up to 20 due jobs per invocation. Failed jobs retry with
database-managed backoff and are marked failed after five attempts. Do not put
phone numbers, gateway credentials, or the service-role key in Flutter config
or client-visible settings.
