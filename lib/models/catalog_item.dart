import 'json_helpers.dart';
import 'item_unit.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    this.itemUnits = const [],
  });

  final int id;
  final String categoryId;
  final String name;
  final int sortOrder;
  final bool isActive;
  final List<ItemUnit> itemUnits;

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final units = json['item_units'];
    final parsedUnits = units is List
        ? units
            .whereType<Map>()
            .map(
              (unit) => ItemUnit.fromJson(
                Map<String, dynamic>.from(unit),
              ),
            )
            .toList()
        : <ItemUnit>[];
    parsedUnits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CatalogItem(
      id: JsonReader.intValue(json, 'id') ?? 0,
      categoryId: JsonReader.string(json, 'category_id'),
      name: JsonReader.string(json, 'name'),
      sortOrder: JsonReader.intValue(json, 'sort_order', defaultValue: 0) ?? 0,
      isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
      itemUnits: parsedUnits,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'sort_order': sortOrder,
        'is_active': isActive,
        'item_units':
            itemUnits.map((unit) => unit.toJson()).toList(growable: false),
      };
}
