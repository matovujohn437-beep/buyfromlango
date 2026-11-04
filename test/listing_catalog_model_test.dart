import 'package:buy_from_lango/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('category parses nested items and units in database order', () {
    final category = Category.fromJson({
      'id': 'crops',
      'label_en': 'Crops',
      'icon_name': 'crops',
      'catalog_items': [
        {
          'id': 12,
          'category_id': 'crops',
          'name': 'Beans',
          'sort_order': 2,
          'item_units': [
            {
              'id': 2,
              'item_id': 12,
              'unit_name': 'bag',
              'sort_order': 2,
            },
            {
              'id': 1,
              'item_id': 12,
              'unit_name': 'kg',
              'sort_order': 1,
            },
          ],
        },
        {
          'id': 11,
          'category_id': 'crops',
          'name': 'Maize',
          'sort_order': 1,
          'item_units': const [],
        },
      ],
    });

    expect(category.catalogItems.map((item) => item.name), ['Maize', 'Beans']);
    expect(
      category.catalogItems.last.itemUnits.map((unit) => unit.unitName),
      ['kg', 'bag'],
    );
    expect(
      Category.fromJson(category.toJson()).catalogItems.last.itemUnits.length,
      2,
    );
  });
}
