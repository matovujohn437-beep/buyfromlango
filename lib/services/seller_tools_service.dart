import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/seller_tag.dart';
import '../models/smart_response.dart';
import '../supabase_config.dart';

class SellerToolsService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<SmartResponseModel>> getSmartResponses(String userId) async {
    final rows = await _client
        .from('smart_responses')
        .select('id, title, content')
        .eq('user_id', userId)
        .order('sort_order')
        .order('id');
    return (rows as List)
        .map((row) =>
            SmartResponseModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> saveSmartResponse({
    required String userId,
    int? id,
    required String title,
    required String content,
  }) async {
    final values = {
      'user_id': userId,
      'title': title.trim(),
      'content': content.trim(),
    };
    if (id == null) {
      await _client.from('smart_responses').insert(values);
    } else {
      await _client
          .from('smart_responses')
          .update(values)
          .eq('id', id)
          .eq('user_id', userId);
    }
  }

  Future<void> deleteSmartResponse({
    required String userId,
    required int id,
  }) async {
    await _client
        .from('smart_responses')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<List<String>> getListingTagKeys({
    required String userId,
    required int listingId,
  }) async {
    final rows = await _client
        .from('listing_tags')
        .select('tag_key')
        .eq('user_id', userId)
        .eq('listing_id', listingId);
    return rows.map((row) => row['tag_key'].toString()).toList();
  }

  Future<List<String>> getChatTagKeys({
    required String userId,
    required int threadId,
  }) async {
    final rows = await _client
        .from('chat_thread_tags')
        .select('tag_key')
        .eq('user_id', userId)
        .eq('thread_id', threadId);
    return rows.map((row) => row['tag_key'].toString()).toList();
  }

  Future<void> setListingTags({
    required int listingId,
    required List<SellerTag> tags,
  }) async {
    await _client.rpc('set_listing_tags', params: {
      'p_listing_id': listingId,
      'p_tag_keys': tags.map((tag) => tag.key).toList(),
    });
  }

  Future<void> setChatTags({
    required int threadId,
    required List<SellerTag> tags,
  }) async {
    await _client.rpc('set_chat_thread_tags', params: {
      'p_thread_id': threadId,
      'p_tag_keys': tags.map((tag) => tag.key).toList(),
    });
  }
}
