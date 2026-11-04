import 'json_helpers.dart';

class BannerModel {
  const BannerModel({
    required this.id,
    this.title,
    required this.imageUrl,
    this.ctaRoute,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String? title;
  final String imageUrl;
  final String? ctaRoute;
  final int sortOrder;
  final bool isActive;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
      title: json['title']?.toString(),
      imageUrl: JsonReader.string(json, 'image_url'),
      ctaRoute: json['cta_route']?.toString(),
      sortOrder: JsonReader.intValue(json, 'sort_order', defaultValue: 0) ?? 0,
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'cta_route': ctaRoute,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
