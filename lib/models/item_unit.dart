import 'json_helpers.dart';

class ItemUnit {
  const ItemUnit({
    required this.id,
    required this.itemId,
    required this.unitName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final int id;
  final int itemId;
  final String unitName;
  final int sortOrder;
  final bool isActive;

  factory ItemUnit.fromJson(Map<String, dynamic> json) => ItemUnit(
        id: JsonReader.intValue(json, 'id') ?? 0,
        itemId: JsonReader.intValue(json, 'item_id') ?? 0,
        unitName: JsonReader.string(json, 'unit_name'),
        sortOrder: JsonReader.intValue(json, 'sort_order', defaultValue: 0) ?? 0,
        isActive: JsonReader.boolValue(json, 'is_active', defaultValue: true),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'unit_name': unitName,
        'sort_order': sortOrder,
        'is_active': isActive,
      };
}
