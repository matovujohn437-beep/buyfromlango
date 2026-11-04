import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/google_sign_in_config.dart';
import '../supabase_config.dart';
import '../utils/ugandan_phone_number.dart';

class GoogleSignInConfigurationException implements Exception {
  const GoogleSignInConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException();

  static const message =
      'An account with this email already exists. Please sign in instead.';

  @override
  String toString() => message;
}

class PhoneAlreadyRegisteredException implements Exception {
  const PhoneAlreadyRegisteredException();

  static const message = 'This phone number is already registered.';

  @override
  String toString() => message;
}

class PhoneLoginException implements Exception {
  const PhoneLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  static Future<void>? _googleInitialization;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse?> signInWithGoogle() async {
    final existingSession = _client.auth.currentSession;
    if (existingSession != null) {
      return AuthResponse(session: existingSession);
    }

    if (kIsWeb && GoogleSignInConfig.clientId.isEmpty) {
      throw const GoogleSignInConfigurationException(
        'Google sign-in is not configured for web. Set '
        'GOOGLE_SIGN_IN_CLIENT_ID and rebuild the app.',
      );
    }
    if (kIsWeb) {
      throw const GoogleSignInConfigurationException(
        'Google sign-in is currently available in the Android app. Web sign-in '
        'requires a Google-rendered sign-in button.',
      );
    }

    try {
      await _ensureGoogleSignInInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInConfigurationException(
          'Google did not return an ID token. Check your Google OAuth client '
          'configuration and try again.',
        );
      }

      try {
        return await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      } on AuthException {
        throw const GoogleSignInConfigurationException(
          'Supabase could not complete Google sign-in. Check your connection '
          'and Google provider settings, then try again.',
        );
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    final initialization = _googleInitialization ??= _initializeGoogleSignIn();
    try {
      await initialization;
    } catch (_) {
      if (identical(_googleInitialization, initialization)) {
        _googleInitialization = null;
      }
      rethrow;
    }
  }

  Future<void> _initializeGoogleSignIn() {
    final serverClientId = GoogleSignInConfig.serverClientId.isNotEmpty
        ? GoogleSignInConfig.serverClientId
        : GoogleSignInConfig.clientId;
    return GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? GoogleSignInConfig.clientId : null,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String identifier,
    required String password,
    bool usePhone = false,
  }) async {
    if (!usePhone) {
      return _client.auth.signInWithPassword(
        email: identifier.trim(),
        password: password,
      );
    }

    final phone = normalizeUgandanPhoneNumber(identifier);
    if (phone == null) {
      throw const PhoneLoginException(
        'Enter a valid Ugandan phone number, such as +256700000000.',
      );
    }
    try {
      final response = await _client.functions.invoke(
        'phone-password-login',
        body: {'phone': phone, 'password': password},
      );
      final data = response.data;
      if (data is! Map || data['refresh_token'] is! String) {
        throw const PhoneLoginException(
          'The phone sign-in service returned an unexpected response.',
        );
      }
      return _client.auth.setSession(data['refresh_token'] as String);
    } on FunctionException catch (error) {
      if (error.status == 401) {
        throw const PhoneLoginException(
            'Phone number or password is incorrect.');
      }
      if (error.status == 0) {
        throw const PhoneLoginException(
          'Could not connect to sign in. Check your connection and try again.',
        );
      }
      throw const PhoneLoginException(
        'Phone sign-in is temporarily unavailable. Please try again.',
      );
    }
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String phone,
    String? fullName,
  }) async {
    if (password.length < 8) {
      throw const FormatException('Use at least 8 characters.');
    }
    final normalizedPhone = normalizeUgandanPhoneNumber(phone);
    if (normalizedPhone == null) {
      throw const FormatException(
        'Enter a valid Ugandan phone number, such as +256700000000.',
      );
    }
    await ensurePhoneAvailable(normalizedPhone);
    try {
      return await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
          'phone': normalizedPhone,
        },
      );
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final code = error.code?.toLowerCase();
      if (error.code == '23505' ||
          message.contains('23505') ||
          message.contains('profiles_phone_unique_idx')) {
        throw const PhoneAlreadyRegisteredException();
      }
      if (code == 'user_already_exists' ||
          message.contains('user already registered') ||
          message.contains('email already exists')) {
        throw const EmailAlreadyRegisteredException();
      }
      rethrow;
    }
  }

  Future<void> ensurePhoneAvailable(String phone) async {
    if (!isCanonicalUgandanPhoneNumber(phone)) {
      throw const FormatException(
        'Enter a valid Ugandan phone number in +256XXXXXXXXX format.',
      );
    }
    final available = await _client.rpc<bool>(
      'is_profile_phone_available',
      params: {'p_phone': phone},
    );
    if (!available) throw const PhoneAlreadyRegisteredException();
  }

  Future<void> savePhoneForCurrentUser({
    required String phone,
    String? fullName,
  }) async {
    final normalizedPhone = normalizeUgandanPhoneNumber(phone);
    if (normalizedPhone == null) {
      throw const FormatException(
        'Enter a valid Ugandan phone number in +256XXXXXXXXX format.',
      );
    }
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in again.');

    final profile = await _client
        .from('profiles')
        .select('phone')
        .eq('id', user.id)
        .maybeSingle();
    if (profile == null) {
      throw const AuthException(
        'Your profile could not be found. Please sign out and sign in again.',
      );
    }
    final existingPhone = profile['phone']?.toString();
    if (existingPhone != null && existingPhone.isNotEmpty) {
      if (existingPhone == normalizedPhone) return;
      throw const PhoneLoginException(
        'This account already has a different phone number. Sign in and update '
        'your number from your profile.',
      );
    }

    await ensurePhoneAvailable(normalizedPhone);
    try {
      await _client.from('profiles').update({
        'phone': normalizedPhone,
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      }).eq('id', user.id);
    } on PostgrestException catch (error) {
      if (error.code == '23505' ||
          error.message.contains('23505') ||
          error.message.contains('profiles_phone_unique_idx')) {
        throw const PhoneAlreadyRegisteredException();
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    final initialization = _googleInitialization;
    if (initialization != null) {
      await initialization;
      await GoogleSignIn.instance.signOut();
    }
  }
}
