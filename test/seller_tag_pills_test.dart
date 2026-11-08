import 'package:buy_from_lango/widgets/seller_tag_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all conversation tags fit a compact row without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: SellerTagPills(
                    tagKeys: [
                      'priority',
                      'follow_up',
                      'coffee_retailer',
                      'repeat_buyer',
                      'maize_bulk_buyer',
                      'new_contact',
                    ],
                  ),
                ),
                Icon(Icons.add),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    for (final label in [
      'Priority',
      'Follow up',
      'Coffee Retailer',
      'Repeat Buyer',
      'Maize Bulk Buyer',
      'New contact',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
