import 'json_helpers.dart';

class BuyerNeedModel {
  const BuyerNeedModel({
    required this.id,
    required this.userId,
    required this.itemName,
    required this.contactPerson,
    required this.districtName,
    this.quantity,
    this.unit,
    this.proposedPriceUgx,
    this.notes,
    this.districtId,
    this.subcountyId,
    this.parishId,
    this.subcountyName,
    this.parishName,
    this.posterName = 'Buyer',
    this.posterAvatarUrl,
    this.posterIsVerified = false,
    this.posterAccountType = 'individual',
    this.itemImageUrl,
    this.categoryId,
    this.createdVia = 'app',
    this.createdAt,
  });

  final int id;
  final String userId;
  final String itemName;
  final String contactPerson;
  final String districtName;
  final num? quantity;
  final String? unit;
  final num? proposedPriceUgx;
  final String? notes;
  final int? districtId;
  final int? subcountyId;
  final int? parishId;
  final String? subcountyName;
  final String? parishName;
  final String posterName;
  final String? posterAvatarUrl;
  final bool posterIsVerified;
  final String posterAccountType;
  final String? itemImageUrl;
  final String? categoryId;
  final String createdVia;
  final DateTime? createdAt;

  factory BuyerNeedModel.fromJson(Map<String, dynamic> json) {
    return BuyerNeedModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      userId: JsonReader.string(json, 'user_id'),
      itemName: JsonReader.string(json, 'item_name'),
      contactPerson: JsonReader.string(json, 'contact_person'),
      districtName: JsonReader.string(json, 'district_name'),
      quantity: JsonReader.numValue(json, 'quantity'),
      unit: json['unit']?.toString(),
      proposedPriceUgx: JsonReader.numValue(json, 'proposed_price_ugx'),
      notes: json['notes']?.toString(),
      districtId: JsonReader.intValue(json, 'district_id'),
      subcountyId: JsonReader.intValue(json, 'subcounty_id'),
      parishId: JsonReader.intValue(json, 'parish_id'),
      subcountyName: json['subcounty_name']?.toString(),
      parishName: json['parish_name']?.toString(),
      posterName: JsonReader.string(
        json,
        'poster_name',
        defaultValue: 'Buyer',
      ),
      posterAvatarUrl: json['poster_avatar_url']?.toString(),
      posterIsVerified: JsonReader.boolValue(json, 'poster_is_verified'),
      posterAccountType: JsonReader.string(
        json,
        'poster_account_type',
        defaultValue: 'individual',
      ),
      itemImageUrl: json['item_image_url']?.toString(),
      categoryId: json['category_id']?.toString(),
      createdVia: JsonReader.string(
        json,
        'created_via',
        defaultValue: 'app',
      ),
      createdAt: JsonReader.dateTime(json, 'created_at'),
    );
  }
}
