import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/catalog_item.dart';
import '../models/category.dart';
import '../supabase_config.dart';

class CategoryService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const _cacheKey = 'public_categories_v1';
  static const _listingCatalogCacheKey = 'public_listing_catalog_v1';

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      final categories = (response as List<dynamic>)
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(categories.map((category) => category.toJson()).toList()),
      );
      return categories;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_cacheKey);
      if (encoded == null) rethrow;
      final rows = jsonDecode(encoded);
      if (rows is! List) rethrow;
      return rows
          .whereType<Map>()
          .map(
            (item) => Category.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
  }

  Future<List<Category>> getListingCatalog() async {
    try {
      final response = await _client
          .from('categories')
          .select('*, catalog_items(*, item_units(*))')
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      final categories = (response as List<dynamic>)
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
          .map(
            (category) => Category(
              id: category.id,
              labelEn: category.labelEn,
              labelLg: category.labelLg,
              iconName: category.iconName,
              sortOrder: category.sortOrder,
              isActive: category.isActive,
              catalogItems: category.catalogItems
                  .where((item) => item.isActive)
                  .map(
                    (item) => CatalogItem(
                      id: item.id,
                      categoryId: item.categoryId,
                      name: item.name,
                      sortOrder: item.sortOrder,
                      isActive: item.isActive,
                      itemUnits: item.itemUnits
                          .where((unit) => unit.isActive)
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _listingCatalogCacheKey,
        jsonEncode(categories.map((category) => category.toJson()).toList()),
      );
      return categories;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_listingCatalogCacheKey);
      if (encoded == null) rethrow;
      final rows = jsonDecode(encoded);
      if (rows is! List) rethrow;
      return rows
          .whereType<Map>()
          .map(
            (item) => Category.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
  }

  Stream<List<Category>> watchCategories() {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .map(
          (rows) => rows
              .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
        );
  }
}
