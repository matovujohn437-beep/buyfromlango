import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/market_price.dart';
import '../supabase_config.dart';

class MarketPriceService {
  static const _cachePrefix = 'market_prices_v1_';
  static const _cacheMaxAge = Duration(days: 30);

  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<MarketPriceModel>> getMarketPrices({int? districtId}) async {
    final cacheKey = '$_cachePrefix${districtId ?? 'all'}';
    try {
      var query = _client.from('market_prices').select(
            'id, district_id, crop_name, price_per_kg_ugx, '
            'farm_gate_price_ugx, recorded_date, trend, '
            'wholesale_price_ugx, retail_price_ugx, price_change_percent, '
            'district:districts!market_prices_district_id_fkey(name)',
          );
      if (districtId != null) {
        query = query.eq('district_id', districtId);
      }
      final response = await query.order('crop_name');
      final rows = (response as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final prices = rows.map(MarketPriceModel.fromJson).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'cachedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
          'prices': rows.map(_cacheRecord).toList(),
        }),
      );
      return prices;
    } catch (_) {
      final cached = await _readCachedPrices(cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Map<String, dynamic> _cacheRecord(Map<String, dynamic> row) => {
        'id': row['id'],
        'district_id': row['district_id'],
        'crop_name': row['crop_name'],
        'price_per_kg_ugx': row['price_per_kg_ugx'],
        'farm_gate_price_ugx': row['farm_gate_price_ugx'],
        'wholesale_price_ugx': row['wholesale_price_ugx'],
        'retail_price_ugx': row['retail_price_ugx'],
        'price_change_percent': row['price_change_percent'],
        'updated_at': row['updated_at'],
        'district': {
          'name': (row['district'] as Map?)?['name'],
        },
      };

  Future<List<MarketPriceModel>?> _readCachedPrices(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(key);
    if (encoded == null) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) return null;
    final cachedAt = decoded['cachedAt'];
    final rows = decoded['prices'];
    if (cachedAt is! int ||
        rows is! List ||
        DateTime.now().toUtc().difference(
                  DateTime.fromMillisecondsSinceEpoch(cachedAt, isUtc: true),
                ) >
            _cacheMaxAge) {
      await prefs.remove(key);
      return null;
    }

    return rows
        .whereType<Map>()
        .map(
          (row) => MarketPriceModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }
}
