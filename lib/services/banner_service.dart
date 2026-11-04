import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/banner.dart';
import '../supabase_config.dart';

class BannerService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<BannerModel>> getBanners() async {
    final response = await _client
        .from('banners')
        .select()
        .eq('is_active', true)
        .lte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('sort_order', ascending: true);
    final list = response as List<dynamic>;
    return list.map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Stream<List<BannerModel>> watchBanners() {
    return _client.from('banners').stream(primaryKey: ['id']).eq('is_active', true).order('sort_order', ascending: true).map(
      (rows) => rows.map((item) => BannerModel.fromJson(Map<String, dynamic>.from(item))).toList(),
    );
  }
}
