import 'package:buy_from_lango/providers/category_provider.dart';
import 'package:buy_from_lango/theme.dart';
import 'package:buy_from_lango/widgets/marketplace_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation shows icons only with accessible labels',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MarketplaceNavigationBar(),
          ),
        ),
      ),
    );

    final navigationBackground = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(MarketplaceNavigationBar),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(navigationBackground.color, AppColors.primaryDark);
    for (final label in ['Back', 'Home', 'Profile', 'Buyer Demands']) {
      expect(find.text(label), findsNothing);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byType(Icon), findsNWidgets(4));
  });
}
