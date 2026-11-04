import 'json_helpers.dart';
import 'catalog_item.dart';

class Category {
  const Category({
    required this.id,
    required this.labelEn,
    this.labelLg,
    required this.iconName,
    this.sortOrder = 0,
    this.isActive = true,
    this.catalogItems = const [],
  });

  final String id;
  final String labelEn;
  final String? labelLg;
  final String iconName;
  final int sortOrder;
  final bool isActive;
  final List<CatalogItem> catalogItems;

  factory Category.fromJson(Map<String, dynamic> json) {
    final catalogItems = json['catalog_items'];
    final parsedItems = catalogItems is List
        ? catalogItems
            .whereType<Map>()
            .map(
              (item) => CatalogItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <CatalogItem>[];
    parsedItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Category(
      id: JsonReader.string(json, 'id'),
      labelEn: JsonReader.string(json, 'label_en'),
      labelLg: json['label_lg']?.toString(),
      iconName: JsonReader.string(json, 'icon_name'),
      sortOrder: JsonReader.intValue(json, 'sort_order', defaultValue: 0) ?? 0,
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
      catalogItems: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label_en': labelEn,
      'label_lg': labelLg,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'is_active': isActive,
      'catalog_items':
          catalogItems.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
