import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

final notificationsProvider = FutureProvider.family<List<AppNotificationModel>, String>((ref, userId) async {
  return ref.read(notificationServiceProvider).getNotifications(userId);
});
