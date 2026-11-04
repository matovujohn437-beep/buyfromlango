import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/district.dart';
import '../models/parish.dart';
import '../models/subcounty.dart';
import '../supabase_config.dart';

class GeoService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<District>> getDistricts() async {
    final response =
        await _client.from('districts').select().eq('is_active', true);
    final list = response as List<dynamic>;
    return list
        .map((item) => District.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Subcounty>> getSubcounties({required int districtId}) async {
    final response = await _client
        .from('subcounties')
        .select()
        .eq('district_id', districtId)
        .eq('is_active', true);
    final list = response as List<dynamic>;
    return list
        .map((item) => Subcounty.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<Parish>> getParishes({required int subcountyId}) async {
    final response = await _client
        .from('parishes')
        .select()
        .eq('subcounty_id', subcountyId)
        .eq('is_active', true);
    final list = response as List<dynamic>;
    return list
        .map((item) => Parish.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
