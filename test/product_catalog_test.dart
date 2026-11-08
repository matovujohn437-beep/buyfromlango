import 'package:buy_from_lango/constants/product_catalog.dart';
import 'package:buy_from_lango/models/category.dart';
import 'package:buy_from_lango/widgets/post_metadata.dart';
import 'package:buy_from_lango/widgets/product_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product dropdown options are defined for each category', () {
    expect(productItemsForCategory('crops'), contains('Maize'));
    expect(productItemsForCategory('livestock'), contains('Goats'));
    expect(productItemsForCategory('livestock'),
        containsAll(['Eggs', 'Milk', 'Beef', 'Pork']));
    expect(productItemsForCategory('equipment'),
        containsAll(['Tractor', 'Water Pump', 'Sprayer']));
    expect(productItemsForCategory('services'), contains('Veterinary care'));
    expect(productItemsForCategory('jobs'), contains('Farm worker'));
    expect(productItemsForCategory('unknown'), isEmpty);
  });

  test('legacy crop items resolve to the crops avatar category', () {
    expect(productCategoryForItem('  MAIZE '), 'crops');
    expect(productCategoryForItem('Goats'), 'livestock');
    expect(productCategoryForItem('Farm worker'), 'jobs');
    expect(productCategoryForItem('Unknown item'), isNull);
  });

  test('catalog models keep new items and item-specific units nested', () {
    final category = Category.fromJson({
      'id': 'livestock',
      'label_en': 'Livestock',
      'icon_name': 'livestock',
      'catalog_items': [
        {
          'id': 1,
          'category_id': 'livestock',
          'name': 'Eggs',
          'item_units': [
            {'id': 1, 'item_id': 1, 'unit_name': 'Trays'},
          ],
        },
        {
          'id': 2,
          'category_id': 'livestock',
          'name': 'Milk',
          'item_units': [
            {'id': 2, 'item_id': 2, 'unit_name': 'Litres'},
          ],
        },
      ],
    });

    expect(category.id, 'livestock');
    expect(category.catalogItems.map((item) => item.name), ['Eggs', 'Milk']);
    expect(category.catalogItems[0].itemUnits.single.unitName, 'Trays');
    expect(category.catalogItems[1].itemUnits.single.unitName, 'Litres');

    final equipment = Category.fromJson({
      'id': 'equipment',
      'label_en': 'Equipment',
      'icon_name': 'equipment',
      'catalog_items': [
        {
          'id': 3,
          'category_id': 'equipment',
          'name': 'Tractor',
          'item_units': [
            {'id': 3, 'item_id': 3, 'unit_name': 'Per Day'},
            {'id': 4, 'item_id': 3, 'unit_name': 'Per Hour'},
            {'id': 5, 'item_id': 3, 'unit_name': 'For Sale'},
          ],
        },
      ],
    });
    expect(equipment.catalogItems.single.name, 'Tractor');
    expect(
      equipment.catalogItems.single.itemUnits.map((unit) => unit.unitName),
      ['Per Day', 'Per Hour', 'For Sale'],
    );
  });

  testWidgets('product avatar uses the matching category icon fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductAvatar(categoryId: 'jobs'),
      ),
    );

    expect(find.byIcon(Icons.work_outline), findsOneWidget);
  });

  testWidgets('broken product image uses the matching category icon fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductAvatar(
          categoryId: 'livestock',
          imageUrl: 'https://example.invalid/missing.png',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pets), findsOneWidget);
  });

  testWidgets('product-specific icons are used for by-products and equipment',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProductAvatar(
          categoryId: 'livestock',
          itemName: 'Milk',
        ),
      ),
    );
    expect(find.byIcon(Icons.local_drink), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProductAvatar(
          categoryId: 'equipment',
          itemName: 'Tractor',
        ),
      ),
    );
    expect(find.byIcon(Icons.agriculture), findsOneWidget);
  });

  testWidgets('post origin and location indicators have helpful tooltips',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PostMetadata(location: 'Lira', createdVia: 'sms'),
      ),
    );

    final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
    expect(tooltips.map((tooltip) => tooltip.message), contains('Lira'));
    expect(
        tooltips.map((tooltip) => tooltip.message), contains('Posted via SMS'));
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
  });
}
