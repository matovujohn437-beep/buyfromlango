import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/buyer_need.dart';
import '../models/chat_thread.dart';
import 'storage_service.dart';
import '../supabase_config.dart';

class BuyerNeedService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<BuyerNeedModel>> getActiveNeeds() async {
    final response = await _client
        .from('public_buyer_needs')
        .select()
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((row) => BuyerNeedModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> createNeed(
    Map<String, dynamic> payload, {
    Uint8List? itemImage,
    String? imageExtension,
  }) async {
    String? uploadedImageUrl;
    if (itemImage != null) {
      if (imageExtension == null) {
        throw ArgumentError.notNull('imageExtension');
      }
      uploadedImageUrl = await StorageService().uploadBuyerNeedImage(
        bytes: itemImage,
        userId: payload['user_id'] as String,
        extension: imageExtension,
      );
    }
    try {
      await _client.from('buyer_needs').insert({
        ...payload,
        if (uploadedImageUrl != null) 'item_image_url': uploadedImageUrl,
      });
    } catch (error) {
      if (uploadedImageUrl != null) {
        try {
          await StorageService().removeBuyerNeedImage(uploadedImageUrl);
        } catch (cleanupError) {
          throw StateError(
            'Could not create buyer request: $error. '
            'The uploaded image could not be removed: $cleanupError',
          );
        }
      }
      rethrow;
    }
  }

  Future<String?> getContactPhone(int needId) async {
    final row = await _client
        .from('buyer_needs')
        .select('contact_phone')
        .eq('id', needId)
        .maybeSingle();
    return row?['contact_phone']?.toString();
  }

  Future<ChatThreadModel> getOrCreateContactThread({
    required int needId,
    required String requesterId,
    required String responderId,
  }) async {
    if (requesterId == responderId) {
      throw ArgumentError('You cannot contact your own request.');
    }
    final existing = await _client
        .from('chat_threads')
        .select()
        .eq('buyer_need_id', needId)
        .eq('buyer_id', responderId)
        .maybeSingle();
    if (existing != null) {
      return ChatThreadModel.fromJson(Map<String, dynamic>.from(existing));
    }
    final response = await _client
        .from('chat_threads')
        .insert({
          'buyer_need_id': needId,
          'buyer_id': responderId,
          'seller_id': requesterId,
        })
        .select()
        .single();
    return ChatThreadModel.fromJson(Map<String, dynamic>.from(response));
  }
}
