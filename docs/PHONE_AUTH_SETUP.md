# Profile phone and password sign-in

The app keeps phone numbers in `public.profiles.phone`. It does not populate
Supabase Auth's built-in phone field. Email/password and Google sign-in remain
available.

## Deploy the database migration

Apply `supabase/migrations/0020_profile_phone_auth.sql` to the Supabase project.
It enforces unique non-null profile phone numbers and creates the
`is_profile_phone_available` RPC used by signup. Resolve any existing duplicate
phone values before applying the migration; PostgreSQL will reject the unique
index rather than choose which account should keep a duplicate number.

## Deploy phone/password sign-in

Deploy the `phone-password-login` Edge Function:

```powershell
supabase functions deploy phone-password-login
```

The function uses the Supabase project's `SUPABASE_URL`,
`SUPABASE_ANON_KEY` (or `SUPABASE_PUBLISHABLE_KEY`), and
`SUPABASE_SERVICE_ROLE_KEY` environment values. Supabase supplies these values
to Edge Functions; never add the service-role key to Flutter, app resources, or
source control. The function uses the service-role key only server-side to map
a profile phone number to its Auth user and email, then uses the public key to
perform the normal password check. It returns only the Supabase session refresh
token and never sends the account email to the app.

Phone inputs are normalized by the app and stored as `+256` followed by nine
digits. The Edge Function accepts only that canonical format and responds with
a generic credential error for an unknown phone or incorrect password.

New email signups use the existing auth-user trigger to create their profile
and default role. Google users without a profile phone are prompted to add one
before completing profile setup. The app checks availability before profile
updates, while the database unique index protects against concurrent signups.
