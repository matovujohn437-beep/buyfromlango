import 'json_helpers.dart';

class ChatThreadModel {
  const ChatThreadModel({
    required this.id,
    this.listingId,
    this.buyerNeedId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessageAt,
    this.createdAt,
    this.buyerDeletedAt,
    this.sellerDeletedAt,
    this.buyerArchivedAt,
    this.sellerArchivedAt,
  });

  final int id;
  final int? listingId;
  final int? buyerNeedId;
  final String buyerId;
  final String sellerId;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? buyerDeletedAt;
  final DateTime? sellerDeletedAt;
  final DateTime? buyerArchivedAt;
  final DateTime? sellerArchivedAt;

  bool isArchivedFor(String userId) => buyerId == userId
      ? buyerArchivedAt != null
      : sellerId == userId && sellerArchivedAt != null;

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      listingId: JsonReader.intValue(json, 'listing_id'),
      buyerNeedId: JsonReader.intValue(json, 'buyer_need_id'),
      buyerId: JsonReader.string(json, 'buyer_id'),
      sellerId: JsonReader.string(json, 'seller_id'),
      lastMessageAt: JsonReader.dateTime(json, 'last_message_at'),
      createdAt: JsonReader.dateTime(json, 'created_at'),
      buyerDeletedAt: JsonReader.dateTime(json, 'buyer_deleted_at'),
      sellerDeletedAt: JsonReader.dateTime(json, 'seller_deleted_at'),
      buyerArchivedAt: JsonReader.dateTime(json, 'buyer_archived_at'),
      sellerArchivedAt: JsonReader.dateTime(json, 'seller_archived_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'buyer_need_id': buyerNeedId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'buyer_deleted_at': buyerDeletedAt?.toIso8601String(),
      'seller_deleted_at': sellerDeletedAt?.toIso8601String(),
      'buyer_archived_at': buyerArchivedAt?.toIso8601String(),
      'seller_archived_at': sellerArchivedAt?.toIso8601String(),
    };
  }
}
