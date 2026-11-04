import 'package:buy_from_lango/providers/connectivity_provider.dart';
import 'package:buy_from_lango/screens/splash_screen.dart';
import 'package:buy_from_lango/widgets/app_logo_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash content fits the viewport without overlapping',
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
            connectivityStatusProvider.overrideWith(
              (ref) => Stream<bool>.value(false),
            ),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final background = tester.widget<Image>(find.byType(Image).first);
      expect(background.fit, BoxFit.contain);
      expect(tester.getSize(find.byType(Image).first), size);
      expect(tester.getTopLeft(find.byType(Image).first), Offset.zero);

      final logo = tester.widget<AppLogoBadge>(find.byType(AppLogoBadge));
      expect(logo.plain, isTrue);
      expect(logo.circular, isTrue);
      expect(
        find.descendant(
          of: find.byType(AppLogoBadge),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
      final logoImage = tester.widget<Image>(
        find.descendant(
          of: find.byType(AppLogoBadge),
          matching: find.byType(Image),
        ),
      );
      expect(logoImage.fit, BoxFit.contain);
      final logoRect = tester.getRect(find.byType(AppLogoBadge));
      expect(logoRect.width, closeTo(logoRect.height, 0.01));
      final startButtonRect = tester.getRect(find.text('Get Started'));
      expect(logoRect.center.dx, closeTo(size.width / 2, 0.01));
      expect(logoRect.bottom, lessThanOrEqualTo(startButtonRect.top));
      expect(startButtonRect.top, greaterThanOrEqualTo(0));
      expect(startButtonRect.bottom, lessThanOrEqualTo(size.height));
      expect(
        tester.getRect(find.text('Browse marketplace')).bottom,
        lessThanOrEqualTo(size.height),
      );
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Browse marketplace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
