import 'json_helpers.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.agreedPriceUgx,
    this.agreedQuantity,
    this.notes,
    this.status = 'negotiating',
    this.phoneRevealedBySeller = false,
    this.type = 'offer',
    this.editCount = 0,
    this.createdAt,
  });

  final int id;
  final int listingId;
  final String buyerId;
  final String sellerId;
  final num? agreedPriceUgx;
  final String? agreedQuantity;
  final String? notes;
  final String status;
  final bool phoneRevealedBySeller;
  final String type;
  final int editCount;
  final DateTime? createdAt;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      listingId: JsonReader.intValue(json, 'listing_id', defaultValue: 0) ?? 0,
      buyerId: JsonReader.string(json, 'buyer_id'),
      sellerId: JsonReader.string(json, 'seller_id'),
      agreedPriceUgx: JsonReader.numValue(json, 'agreed_price_ugx'),
      agreedQuantity: json['agreed_quantity']?.toString(),
      notes: json['notes']?.toString(),
      status: JsonReader.string(json, 'status', defaultValue: 'negotiating'),
      phoneRevealedBySeller:
          JsonReader.boolValue(json, 'phone_revealed_by_seller'),
      type: JsonReader.string(json, 'type', defaultValue: 'offer'),
      editCount: JsonReader.intValue(json, 'edit_count', defaultValue: 0) ?? 0,
      createdAt: JsonReader.dateTime(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'agreed_price_ugx': agreedPriceUgx,
      'agreed_quantity': agreedQuantity,
      'notes': notes,
      'status': status,
      'phone_revealed_by_seller': phoneRevealedBySeller,
      'type': type,
      'edit_count': editCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
