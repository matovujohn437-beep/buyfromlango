# Buy From Lango Google OAuth setup

## Local Android configuration

- Application name: **Buy From Lango**
- Android application ID / namespace: `ug.co.buyfromlango.app`
- Supabase project URL: `https://ospfxilvkgkamcgjluzb.supabase.co`
- Supabase project reference: `ospfxilvkgkamcgjluzb`
- Supabase Google callback URI:
  `https://ospfxilvkgkamcgjluzb.supabase.co/auth/v1/callback`

Verified with `android\gradlew.bat signingReport` on 2026-11-03:

| Variant | Gradle signing config | Keystore | Alias | SHA-1 | SHA-256 |
|---|---|---|---|---|---|
| Debug | debug | `C:\Users\baker\.android\debug.keystore` | `AndroidDebugKey` (`androiddebugkey` in keytool) | `DC:D0:4C:C4:50:8D:CE:BC:3F:49:60:84:4A:08:A3:D6:6F:DE:57:0D` | `FA:1E:00:0A:C1:1F:62:5F:49:20:63:40:1C:2A:19:6B:D6:9D:0B:66:46:4D:5F:CD:12:59:94:F6:6D:FA:27:EA` |
| Release (current local configuration only) | debug | `C:\Users\baker\.android\debug.keystore` | `AndroidDebugKey` | Same as debug | Same as debug |

The Gradle release build type currently points at the **debug** signing config.
The release fingerprints above are therefore not a production release
certificate. Configure your production keystore before distribution, then run
`cd android; .\gradlew.bat signingReport` again and register that certificate's
SHA-1 as a separate Android OAuth client. Never put keystore passwords or
private signing material in this document or source control.

The keystore path above is for this development machine only. Android's
standard debug keystore password is not documented or needed for Google Cloud
registration.

## Google Cloud Console

Open [Google Cloud Console credentials](https://console.cloud.google.com/apis/credentials)
for the Google Cloud project that will be used for Buy From Lango. Configure
the OAuth consent screen and add the required test users if the app remains in
testing mode.

### Android OAuth client (debug)

Create an OAuth client with:

- Application type: **Android**
- Name: **Buy From Lango Android**
- Package name: `ug.co.buyfromlango.app`
- SHA-1 certificate fingerprint:
  `DC:D0:4C:C4:50:8D:CE:BC:3F:49:60:84:4A:08:A3:D6:6F:DE:57:0D`

Create another Android OAuth client for the production release certificate
after a production keystore is configured. Do not use the current release
variant's debug fingerprint for a production release.

### Web OAuth client (Supabase)

Create a separate OAuth client with:

- Application type: **Web application**
- Name: **Buy From Lango Supabase**
- Authorized redirect URI:
  `https://ospfxilvkgkamcgjluzb.supabase.co/auth/v1/callback`

After creation, copy its **Client ID** and **Client Secret**. The Client ID is
used by the app as the Google server client ID; the Client Secret belongs only
in Supabase. Never place the Client Secret in Flutter code, `--dart-define`,
Android resources, or source control.

## Supabase Dashboard

In the Supabase project `ospfxilvkgkamcgjluzb`, open:

**Authentication → Sign In / Providers → Google**

Enable Google, then paste the Web OAuth **Client ID** and **Client Secret** and
save. Supabase's Google provider requires both. The callback URI above must
also be registered as an authorized redirect URI on that Web OAuth client.

The app continues to use the existing Supabase URL and publishable client key.
Do not replace them with a service-role key; service-role credentials must
never be shipped in the Android app.

## Flutter client ID configuration

The integration uses `google_sign_in` 7.2.0's `GoogleSignIn.instance`,
`initialize`, and `authenticate` APIs, then exchanges the Google ID token with
`supabase.auth.signInWithIdToken()`. Pass the Web OAuth Client ID as the
server client ID when running/building Android:

```powershell
flutter run --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=<web-client-id>
```

Use the same define in the corresponding release build command or CI
configuration. Client IDs are not secrets; the Web Client Secret is. The
current sign-in screen is implemented for Android; `google_sign_in` 7.x web
authentication requires rendering Google's own sign-in button and is not
implemented in these screens.

## Existing Supabase users and roles

No auth schema, profile table, role table, trigger, or Row Level Security policy
was changed for Google sign-in. New Google users are created by Supabase Auth
and follow the project's existing auth-user trigger/profile defaults; existing
accounts are resolved by Supabase Auth. The client does not assign roles or
administrator privileges.

The checked-in migrations define a default `profiles.role` and an
`on_auth_user_created` trigger that inserts profiles with `ON CONFLICT DO
NOTHING`. They do not define a `user_roles` table; if the live Supabase project
has additional role structures, keep their existing server-side triggers and
policies authoritative.

## Verification status

Local dependency resolution, static analysis, tests, signing report, and debug
APK build are run as part of this task. Google Cloud OAuth clients and the
Supabase Google provider must still be configured by a project administrator.
Successful live Google sign-in cannot be claimed until those credentials are
configured and tested on a device with this package ID and signing
certificate.
