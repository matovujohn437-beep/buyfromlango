import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final ordersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  return ref.read(orderServiceProvider).watchOrdersForUser(userId);
});

final sellerPhoneSmsStatusProvider =
    FutureProvider.autoDispose.family<String?, int>((ref, orderId) async {
  final status =
      await ref.read(orderServiceProvider).getSellerPhoneSmsStatus(orderId);
  if (status == 'queued' || status == 'processing') {
    final timer = Timer(const Duration(seconds: 10), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return status;
});
