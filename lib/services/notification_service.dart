import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification.dart';
import '../supabase_config.dart';

class NotificationService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<AppNotificationModel>> getNotifications(String userId) async {
    final response = await _client.from('notifications').select().eq('user_id', userId).order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item))).toList());
  }
}
