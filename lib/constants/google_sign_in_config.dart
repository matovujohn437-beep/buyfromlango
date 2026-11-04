class GoogleSignInConfig {
  GoogleSignInConfig._();

  static const clientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_CLIENT_ID',
  );
  static const serverClientId = String.fromEnvironment(
    'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
  );
}
