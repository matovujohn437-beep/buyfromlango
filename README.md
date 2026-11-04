# Buy From Lango

Flutter marketplace app for farmers and buyers in Lango, Uganda.

## Google sign-in configuration

Enable Google as an Auth provider in the Supabase project and configure the
matching OAuth client IDs in Google Cloud. The current Google sign-in button
flow is implemented for Android. The `google_sign_in` 7.x web flow requires a
Google-rendered sign-in button and is not enabled by these screens.

For Android, configure the Android OAuth client and SHA fingerprints. To get
Google ID tokens for Supabase, also provide the web/server OAuth client ID:

```powershell
flutter run --dart-define=GOOGLE_SIGN_IN_SERVER_CLIENT_ID=<web-client-id>
```

The server client ID defaults to `GOOGLE_SIGN_IN_CLIENT_ID` when only one
client ID is supplied. Do not commit OAuth client secrets to the app.

## Seller tools setup

Apply the Supabase migration before using Smart Responses or seller Tags. See
[the seller tools setup guide](docs/SELLER_TOOLS_SETUP.md).
