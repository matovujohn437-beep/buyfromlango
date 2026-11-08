import 'json_helpers.dart';

class ListingModel {
  const ListingModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    this.description,
    this.priceUgx,
    this.isNegotiable = true,
    this.quantity,
    this.unit,
    this.workersNeeded,
    this.serviceType,
    this.remainingQuantity,
    this.saleStatus = 'available',
    this.privacy = 'public',
    this.districtId,
    this.subcountyId,
    this.parishId,
    this.status = 'active',
    this.isAnonymous = false,
    this.isFeatured = false,
    this.editCount = 0,
    this.viewCount = 0,
    this.isCachedOffline = false,
    this.districtName,
    this.imageUrl,
    this.createdVia = 'app',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String userId;
  final String categoryId;
  final String title;
  final String? description;
  final num? priceUgx;
  final bool isNegotiable;
  final String? quantity;
  final String? unit;
  final int? workersNeeded;
  final String? serviceType;
  final num? remainingQuantity;
  final String saleStatus;
  final String privacy;
  final int? districtId;
  final int? subcountyId;
  final int? parishId;
  final String status;
  final bool isAnonymous;
  final bool isFeatured;
  final int editCount;
  final int viewCount;
  final bool isCachedOffline;
  final String? districtName;
  final String? imageUrl;
  final String createdVia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFullySold => saleStatus == 'fully_sold' || saleStatus == 'sold';

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      userId: JsonReader.string(json, 'user_id'),
      categoryId: JsonReader.string(json, 'category_id'),
      title: JsonReader.string(json, 'title'),
      description: json['description']?.toString(),
      priceUgx: JsonReader.numValue(json, 'price_ugx'),
      isNegotiable:
          JsonReader.boolValue(json, 'is_negotiable', defaultValue: true),
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      workersNeeded: JsonReader.intValue(json, 'workers_needed'),
      serviceType: json['service_type']?.toString(),
      remainingQuantity: JsonReader.numValue(json, 'remaining_quantity'),
      saleStatus: JsonReader.string(
        json,
        'sale_status',
        defaultValue: 'available',
      ),
      privacy: JsonReader.string(json, 'privacy', defaultValue: 'public'),
      districtId: JsonReader.intValue(json, 'district_id'),
      subcountyId: JsonReader.intValue(json, 'subcounty_id'),
      parishId: JsonReader.intValue(json, 'parish_id'),
      status: JsonReader.string(json, 'status', defaultValue: 'active'),
      isAnonymous: JsonReader.boolValue(json, 'is_anonymous'),
      isFeatured: JsonReader.boolValue(json, 'is_featured'),
      editCount: JsonReader.intValue(json, 'edit_count', defaultValue: 0) ?? 0,
      viewCount: JsonReader.intValue(json, 'view_count', defaultValue: 0) ?? 0,
      isCachedOffline: JsonReader.boolValue(json, 'is_cached_offline'),
      districtName: (json['district'] as Map?)?['name']?.toString() ??
          json['district_name']?.toString(),
      imageUrl: _firstListingImageUrl(json['listing_media']) ??
          json['image_url']?.toString(),
      createdVia: JsonReader.string(
        json,
        'created_via',
        defaultValue: 'app',
      ),
      createdAt: JsonReader.dateTime(json, 'created_at'),
      updatedAt: JsonReader.dateTime(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price_ugx': priceUgx,
      'is_negotiable': isNegotiable,
      'quantity': quantity,
      'unit': unit,
      'workers_needed': workersNeeded,
      'service_type': serviceType,
      'remaining_quantity': remainingQuantity,
      'sale_status': saleStatus,
      'privacy': privacy,
      'district_id': districtId,
      'subcounty_id': subcountyId,
      'parish_id': parishId,
      'status': status,
      'is_anonymous': isAnonymous,
      'is_featured': isFeatured,
      'edit_count': editCount,
      'view_count': viewCount,
      'district_name': districtName,
      'image_url': imageUrl,
      'created_via': createdVia,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

String? _firstListingImageUrl(dynamic media) {
  if (media is! List) return null;
  for (final item in media) {
    if (item is Map && (item['media_type']?.toString() ?? 'image') == 'image') {
      final url = item['media_url']?.toString().trim();
      if (url != null && url.isNotEmpty) return url;
    }
  }
  return null;
}

class ListingMediaModel {
  const ListingMediaModel({
    required this.mediaUrl,
    this.mediaType = 'image',
  });

  final String mediaUrl;
  final String mediaType;

  factory ListingMediaModel.fromJson(Map<String, dynamic> json) =>
      ListingMediaModel(
        mediaUrl: json['media_url']?.toString() ?? '',
        mediaType: json['media_type']?.toString() ?? 'image',
      );
}

String? primaryListingImageUrl(
  ListingModel listing, [
  List<ListingMediaModel>? media,
]) {
  final imageUrl = listing.imageUrl?.trim();
  if (imageUrl?.isNotEmpty == true) return imageUrl;

  for (final item in media ?? const <ListingMediaModel>[]) {
    final mediaUrl = item.mediaUrl.trim();
    if (item.mediaType == 'image' && mediaUrl.isNotEmpty) return mediaUrl;
  }
  return null;
}
