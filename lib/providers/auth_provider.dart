import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../supabase_config.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.session?.user ??
      ref.watch(authServiceProvider).currentUser;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (response == null) return null;
  return ProfileModel.fromJson({
    ...Map<String, dynamic>.from(response),
    'email': user.email,
  });
});
