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

      for (var page = 0; page < 3; page++) {
        final image = tester.widget<Image>(find.byType(Image).first);
        final imageSize = tester.getSize(find.byType(Image).first);
        final imageRect = tester.getRect(find.byType(Image).first);

        expect(image.fit, BoxFit.contain);
        expect(imageSize.height, lessThan(size.height));
        expect(imageSize.width, lessThanOrEqualTo(size.width));
        expect(imageRect.left, greaterThanOrEqualTo(0));
        expect(imageRect.right, lessThanOrEqualTo(size.width));
        expect(imageRect.bottom, lessThan(size.height));
        expect(
          tester.getRect(find.text('Log in')).bottom,
          lessThanOrEqualTo(size.height),
        );
        final action = page == 2 ? 'Get Started' : 'Next';
        final actionRect = tester.getRect(find.text(action));
        expect(actionRect.top, greaterThanOrEqualTo(0));
        expect(actionRect.bottom, lessThanOrEqualTo(size.height));

        final title = [
          'Welcome to Buy From Lango',
          'Easy, secure and local',
          'Grow together',
        ][page];
        final description = [
          'Your marketplace for agricultural produce, services, jobs and more.',
          'Use SMS, mobile app or phone. Find what you need and connect with confidence.',
          'Reach local buyers, discover opportunities and grow your business.',
        ][page];
        for (final text in [title, description]) {
          final rect = tester.getRect(find.text(text));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        expect(
          imageRect.bottom,
          lessThanOrEqualTo(tester.getTopLeft(find.text(title)).dy),
        );
        expect(tester.takeException(), isNull);

        if (page < 2) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    }
  });
}
