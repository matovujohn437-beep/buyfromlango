import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../supabase_config.dart';

class OrderService {
  final SupabaseClient _client = SupabaseConfig.client;

  Stream<List<OrderModel>> watchOrdersForUser(String userId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .where(
                (item) =>
                    item['buyer_id'] == userId || item['seller_id'] == userId,
              )
              .map(
                (item) => OrderModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
  }

  Future<OrderModel> createOrder(Map<String, dynamic> payload) async {
    final response =
        await _client.from('orders').insert(payload).select().single();
    return OrderModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<OrderModel> requestSellerContact({
    required int listingId,
    required String buyerId,
    required String sellerId,
    required String listingTitle,
  }) async {
    final buyer = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', buyerId)
        .single();
    final buyerName = buyer['full_name']?.toString().trim();
    final requestMessage =
        'Buy From Lango: ${buyerName == null || buyerName.isEmpty ? 'A buyer' : buyerName} '
        'has requested your contact for $listingTitle. Reply REVEAL to share your number.';

    final existingRequest = await _client
        .from('orders')
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .eq('type', 'contact_request')
        .eq('status', 'negotiating')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final order = existingRequest == null
        ? await createOrder({
            'listing_id': listingId,
            'buyer_id': buyerId,
            'seller_id': sellerId,
            'status': 'negotiating',
            'type': 'contact_request',
          })
        : OrderModel.fromJson(
            Map<String, dynamic>.from(existingRequest),
          );

    await queueContactRequestSms(
      orderId: order.id,
      message: requestMessage,
    );
    return order;
  }

  Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    final response = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select()
        .single();
    return OrderModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<OrderModel> updateOrderTerms({
    required int orderId,
    required num priceUgx,
    required String? quantity,
  }) async {
    final response = await _client
        .from('orders')
        .update({
          'agreed_price_ugx': priceUgx,
          'agreed_quantity': quantity,
        })
        .eq('id', orderId)
        .select()
        .single();
    return OrderModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<void> acceptContactRequest(int orderId) async {
    await _client.rpc(
      'accept_contact_request',
      params: {'p_order_id': orderId},
    );
  }

  Future<String> queueContactRequestSms({
    required int orderId,
    required String message,
  }) async {
    final response = await _client.rpc(
      'queue_notification_sms',
      params: {
        'p_order_id': orderId,
        'p_message': message,
      },
    );
    return response?.toString() ?? 'queued';
  }

  Future<String> getRevealedSellerPhone(int orderId) async {
    final response = await _client.rpc(
      'get_revealed_seller_phone',
      params: {'p_order_id': orderId},
    );
    final phone = response?.toString().trim() ?? '';
    if (phone.isEmpty) {
      throw StateError('The seller has not shared a phone number.');
    }
    return phone;
  }

  Future<String> requestSellerPhoneSms(int orderId) async {
    final response = await _client.rpc(
      'request_seller_phone_sms',
      params: {'p_order_id': orderId},
    );
    return response.toString();
  }

  Future<String?> getSellerPhoneSmsStatus(int orderId) async {
    final response = await _client
        .from('seller_phone_sms_queue')
        .select('status')
        .eq('order_id', orderId)
        .maybeSingle();
    return response?['status']?.toString();
  }
}
