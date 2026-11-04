import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_thread.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatThreadProvider =
    FutureProvider.family<ChatThreadModel, int>((ref, threadId) {
  return ref.watch(chatServiceProvider).getThread(threadId);
});

final chatThreadsProvider =
    FutureProvider.family<List<ChatThreadModel>, String>((ref, userId) async {
  return ref.read(chatServiceProvider).getThreadsForUser(userId);
});

final watchedChatThreadsProvider =
    StreamProvider.family<List<ChatThreadModel>, String>((ref, userId) {
  return ref.read(chatServiceProvider).watchThreadsForUser(userId);
});

final threadMessagesProvider =
    StreamProvider.family<List<MessageModel>, int>((ref, threadId) {
  return ref.read(chatServiceProvider).watchMessages(threadId);
});
