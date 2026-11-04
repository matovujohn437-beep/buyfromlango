import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_thread.dart';
import '../models/message.dart';
import '../supabase_config.dart';

class ChatService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<String> getThreadContextTitle(ChatThreadModel thread) async {
    if (thread.buyerNeedId != null) {
      final need = await _client
          .from('buyer_needs')
          .select('item_name')
          .eq('id', thread.buyerNeedId!)
          .maybeSingle();
      return need?['item_name']?.toString() ?? 'Buyer request';
    }
    if (thread.listingId != null) {
      final listing = await _client
          .from('listings')
          .select('title')
          .eq('id', thread.listingId!)
          .maybeSingle();
      return listing?['title']?.toString() ?? 'Listing #${thread.listingId}';
    }
    return 'Conversation';
  }

  Future<ChatThreadModel> getOrCreateThread({
    required int listingId,
    required String buyerId,
    required String sellerId,
  }) async {
    if (buyerId == sellerId) {
      throw ArgumentError('A seller cannot start a chat with themselves.');
    }

    final existing = await _client
        .from('chat_threads')
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', buyerId)
        .maybeSingle();
    if (existing != null) {
      return ChatThreadModel.fromJson(Map<String, dynamic>.from(existing));
    }

    final response = await _client
        .from('chat_threads')
        .insert({
          'listing_id': listingId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
        })
        .select()
        .single();
    return ChatThreadModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<List<ChatThreadModel>> getThreadsForUser(String userId) async {
    final response = await _client
        .from('chat_threads')
        .select()
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false);
    final list = response as List<dynamic>;
    return list
        .map(
            (item) => ChatThreadModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ChatThreadModel> getThread(int threadId) async {
    final response =
        await _client.from('chat_threads').select().eq('id', threadId).single();
    return ChatThreadModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<ChatThreadModel?> getLatestThreadBetweenUsers({
    required String firstUserId,
    required String secondUserId,
  }) async {
    final response = await _client
        .from('chat_threads')
        .select()
        .or(
          'and(buyer_id.eq.$firstUserId,seller_id.eq.$secondUserId),'
          'and(buyer_id.eq.$secondUserId,seller_id.eq.$firstUserId)',
        )
        .order('last_message_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return ChatThreadModel.fromJson(Map<String, dynamic>.from(response));
  }

  Stream<List<ChatThreadModel>> watchThreadsForUser(String userId) {
    return _client.from('chat_threads').stream(primaryKey: ['id']).map(
      (rows) => rows
          .where(
            (row) => row['buyer_id'] == userId || row['seller_id'] == userId,
          )
          .map((row) => ChatThreadModel.fromJson(row))
          .toList()
        ..sort(
          (a, b) => (b.lastMessageAt ?? b.createdAt ?? DateTime(0))
              .compareTo(a.lastMessageAt ?? a.createdAt ?? DateTime(0)),
        ),
    );
  }

  Stream<List<MessageModel>> watchMessages(int threadId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .map((rows) => rows
            .map((item) =>
                MessageModel.fromJson(Map<String, dynamic>.from(item)))
            .toList());
  }

  Future<void> sendMessage(Map<String, dynamic> payload) async {
    await _client.from('messages').insert(payload);
  }

  Future<String> uploadChatMedia({
    required Uint8List bytes,
    required int threadId,
    required String userId,
    required String extension,
    required String contentType,
  }) async {
    final path =
        '$threadId/$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _client.storage.from('chat-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  Future<String> createSignedChatMediaUrl(String path) {
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return Future.value(path);
    }
    return _client.storage.from('chat-media').createSignedUrl(path, 3600);
  }

  Future<Uint8List> downloadChatMedia(String path) {
    return _client.storage.from('chat-media').download(path);
  }
}
