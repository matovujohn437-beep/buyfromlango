import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class SmsService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<void> logSms({
    required String direction,
    required String phone,
    required String message,
    String status = 'queued',
    String? relatedUserId,
  }) async {
    await _client.from('sms_log').insert({
      'direction': direction,
      'phone': phone,
      'message': message,
      'status': status,
      'related_user_id': relatedUserId,
    });
  }
}
