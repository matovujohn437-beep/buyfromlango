import 'package:buy_from_lango/providers/category_provider.dart';
import 'package:buy_from_lango/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every onboarding page fits the viewport without scrolling',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(320, 320),
      const Size(320, 360),
      const Size(320, 480),
      const Size(390, 844),
      const Size(844, 390),
      const Size(1280, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: OnboardingScreen(key: ValueKey(size))),
        ),
      );
      await tester.pumpAndSettle();

      final glassPanel = tester.widget<Container>(
        find.byKey(const ValueKey('onboarding-glass-panel')),
      );
      expect(
        (glassPanel.decoration! as BoxDecoration).color,
        const Color(0xE62E5C31),
      );

      for (var page = 0; page < 8; page++) {
        final image = tester.widget<Image>(find.byType(Image).first);
        final imageSize = tester.getSize(find.byType(Image).first);
        final imageRect = tester.getRect(find.byType(Image).first);

        expect(image.fit, BoxFit.cover);
        expect(imageSize.height, size.height);
        expect(imageSize.width, size.width);
        expect(imageRect.left, greaterThanOrEqualTo(0));
        expect(imageRect.right, lessThanOrEqualTo(size.width));
        final skipButton = find.text('Skip').hitTestable();
        expect(skipButton, page == 7 ? findsNothing : findsOneWidget);
        if (page < 7) {
          expect(
            tester.getRect(skipButton).bottom,
            lessThanOrEqualTo(size.height),
          );
        }
        final action = page == 7 ? 'Get Started' : 'Next';
        final actionRect = tester.getRect(find.text(action));
        expect(actionRect.top, greaterThanOrEqualTo(0));
        expect(actionRect.bottom, lessThanOrEqualTo(size.height));

        final title = [
          'Welcome to Buy From Lango',
          'Sell Your Harvest',
          'Buy Fresh & Local',
          'Works on Any Phone',
          'Know the Real Prices',
          'Reveal Contacts Safely',
          'Services & Jobs',
          'Ready to Grow?',
        ][page];
        final description = [
          'Connect directly with local farmers.',
          'No brokers, no middlemen. Keep 100% of your profits.',
          'Browse listings from verified farmers in your district.',
          "Smartphone or feature phone? We've got you covered with our SMS gateway.",
          'Check daily market, farm gate, and retail prices before you trade.',
          "Request a seller's number securely via SMS.",
          'Find tractor operators, herders, and farm labor instantly.',
          'Join thousands of farmers transforming agriculture in Northern Uganda.',
        ][page];
        for (final text in [title, description]) {
          final rect = tester.getRect(find.text(text));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(tester.takeException(), isNull);

        if (page < 7) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    }
  });
}
