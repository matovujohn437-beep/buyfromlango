import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listing.dart';
import '../models/profile.dart';
import '../supabase_config.dart';

class ListingPageResult {
  const ListingPageResult({
    required this.listings,
    this.isFromCache = false,
  });

  final List<ListingModel> listings;
  final bool isFromCache;
}

class ListingService {
  final SupabaseClient _client = SupabaseConfig.client;
  static const _cachePrefix = 'public_listing_page_v1_';
  static const _maxCachedPages = 40;
  static const _cacheMaxAge = Duration(days: 7);

  Future<List<ListingModel>> getFeaturedListings() async {
    final response = await _client
        .from('listings')
        .select('*, district:districts(name)')
        .eq('status', 'active')
        .neq('sale_status', 'fully_sold')
        .eq('is_featured', true)
        .order('created_at', ascending: false)
        .limit(6);
    final list = response as List<dynamic>;
    return list
        .map((item) => ListingModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ListingModel>> getMyActiveListings(String userId) async {
    final response = await _client
        .from('listings')
        .select('*, district:districts(name)')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map(
          (row) => ListingModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ListingPageResult> getListings({
    int limit = 20,
    int offset = 0,
    String? categoryId,
    String? searchQuery,
    int? districtId,
    int? subcountyId,
    int? parishId,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Cannot be negative.');
    }

    final normalizedQuery = searchQuery?.trim();
    final cacheKey = _listingCacheKey(
      categoryId: categoryId,
      searchQuery: normalizedQuery,
      districtId: districtId,
      subcountyId: subcountyId,
      parishId: parishId,
      offset: offset,
      limit: limit,
    );
    try {
      var query = _client
          .from('listings')
          .select('*, district:districts(name)')
          .eq('status', 'active')
          .neq('sale_status', 'fully_sold');
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }
      if (districtId != null) {
        query = query.eq('district_id', districtId);
      }
      if (subcountyId != null) {
        query = query.eq('subcounty_id', subcountyId);
      }
      if (parishId != null) {
        query = query.eq('parish_id', parishId);
      }
      if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
        query = query.ilike('title', '%$normalizedQuery%');
      }
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final rows = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final prefs = await SharedPreferences.getInstance();
      final sanitizedRows = rows.map(_publicListingCacheRecord).toList();
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'cachedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
          'listings': sanitizedRows,
        }),
      );
      await _pruneListingCache(prefs, preserveKey: cacheKey);
      return ListingPageResult(
        listings: rows.map(ListingModel.fromJson).toList(),
      );
    } catch (error) {
      final cached = await _readCachedListings(cacheKey);
      if (cached != null) {
        return ListingPageResult(listings: cached, isFromCache: true);
      }
      rethrow;
    }
  }

  Future<void> clearCachedListings() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKeys =
        prefs.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
    for (final key in cacheKeys) {
      await prefs.remove(key);
    }
  }

  Future<ListingModel> getListingById(int listingId) async {
    try {
      final response = await _client
          .from('listings')
          .select('*, district:districts(name)')
          .eq('id', listingId)
          .single();
      return ListingModel.fromJson(Map<String, dynamic>.from(response));
    } catch (_) {
      final cached = await _findCachedListing(listingId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  String _listingCacheKey({
    required String? categoryId,
    required String? searchQuery,
    required int? districtId,
    required int? subcountyId,
    required int? parishId,
    required int offset,
    required int limit,
  }) {
    final filters = [
      _client.auth.currentUser?.id ?? 'guest',
      categoryId ?? '',
      Uri.encodeComponent(searchQuery ?? ''),
      districtId?.toString() ?? '',
      subcountyId?.toString() ?? '',
      parishId?.toString() ?? '',
      offset,
      limit,
    ].join('_');
    return '$_cachePrefix$filters';
  }

  Map<String, dynamic> _publicListingCacheRecord(
    Map<String, dynamic> row,
  ) =>
      {
        'id': row['id'],
        'category_id': row['category_id'],
        'title': row['title'],
        'description': row['description'],
        'image_url': row['image_url'],
        'price_ugx': row['price_ugx'],
        'is_negotiable': row['is_negotiable'],
        'quantity': row['quantity'],
        'unit': row['unit'],
        'district_id': row['district_id'],
        'district_name': (row['district'] as Map?)?['name'],
        'remaining_quantity': row['remaining_quantity'],
        'created_via': row['created_via'],
        'sale_status': row['sale_status'],
        'status': 'active',
        'created_at': row['created_at'],
      };

  Future<List<ListingModel>?> _readCachedListings(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(key);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) return null;
    final cachedAt = decoded['cachedAt'];
    final rows = decoded['listings'];
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
          (item) => ListingModel.fromJson({
            ...Map<String, dynamic>.from(item),
            'user_id': '',
            'is_cached_offline': true,
          }),
        )
        .toList();
  }

  Future<ListingModel?> _findCachedListing(int listingId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(_cachePrefix))) {
      final listings = await _readCachedListings(key);
      final match =
          listings?.where((listing) => listing.id == listingId).firstOrNull;
      if (match != null) return match;
    }
    return null;
  }

  Future<void> _pruneListingCache(
    SharedPreferences prefs, {
    required String preserveKey,
  }) async {
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_cachePrefix) && key != preserveKey)
        .toList();
    if (keys.length < _maxCachedPages) return;
    for (final key in keys.take(keys.length - _maxCachedPages + 1)) {
      await prefs.remove(key);
    }
  }

  Future<List<ListingMediaModel>> getListingMedia(int listingId) async {
    final response = await _client
        .from('listing_media')
        .select('media_url, media_type')
        .eq('listing_id', listingId)
        .order('sort_order', ascending: true);
    return (response as List<dynamic>)
        .map(
          (item) => ListingMediaModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> addListingMedia({
    required int listingId,
    required String mediaUrl,
    required String mediaType,
    required int sortOrder,
  }) async {
    final existing = await _client
        .from('listing_media')
        .select('id')
        .eq('listing_id', listingId)
        .eq('media_url', mediaUrl)
        .maybeSingle();
    if (existing != null) return;

    final lastMedia = await _client
        .from('listing_media')
        .select('sort_order')
        .eq('listing_id', listingId)
        .order('sort_order', ascending: false)
        .limit(1)
        .maybeSingle();
    final lastSortOrder = (lastMedia?['sort_order'] as num?)?.toInt() ?? -1;
    await _client.from('listing_media').insert({
      'listing_id': listingId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'sort_order': sortOrder > lastSortOrder ? sortOrder : lastSortOrder + 1,
    });
  }

  Future<ProfileModel?> getSellerProfile(String userId) async {
    final response = await _client
        .from('public_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response == null) return null;
    return ProfileModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<ProfileModel?> getSellerCatalogProfile(String userId) async {
    final profile = await getSellerProfile(userId);
    if (profile == null || profile.districtId == null) return profile;

    final district = await _client
        .from('districts')
        .select('name')
        .eq('id', profile.districtId!)
        .maybeSingle();
    if (district == null) return profile;

    return ProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      phone: profile.phone,
      email: profile.email,
      hasEmail: profile.hasEmail,
      role: profile.role,
      accountType: profile.accountType,
      itemVisibility: profile.itemVisibility,
      districtId: profile.districtId,
      subcountyId: profile.subcountyId,
      parishId: profile.parishId,
      isAnonymous: profile.isAnonymous,
      isVerified: profile.isVerified,
      isAdmin: profile.isAdmin,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      districtName: district['name']?.toString(),
      createdAt: profile.createdAt,
    );
  }

  Future<List<ListingModel>> getSellerCatalogListings(String userId) async {
    final response = await _client
        .from('listings')
        .select(
          '*, district:districts(name), '
          'listing_media(media_url, media_type, sort_order)',
        )
        .eq('user_id', userId)
        .eq('status', 'active')
        .neq('sale_status', 'fully_sold')
        .order('created_at', ascending: false)
        .order('sort_order', referencedTable: 'listing_media');
    return (response as List<dynamic>)
        .map(
          (row) => ListingModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<ListingModel> createListing(Map<String, dynamic> payload) async {
    final response =
        await _client.from('listings').insert(payload).select().single();
    return ListingModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<ListingModel> updateListing(
    int listingId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .from('listings')
        .update(payload)
        .eq('id', listingId)
        .select()
        .single();
    return ListingModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> removeListing(int listingId) async {
    await _client
        .from('listings')
        .update({'status': 'closed'})
        .eq('id', listingId)
        .select('id')
        .single();
  }
}
