import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static const String supabaseUrl = 'https://ospfxilvkgkamcgjluzb.supabase.co';
  static const String supabaseKey =
      'sb_publishable_6Ect8lCkb8L-SgivCG-7Lg_ZdOgUogz';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
