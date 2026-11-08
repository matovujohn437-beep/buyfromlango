import 'package:buy_from_lango/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        const MaterialApp(home: SplashScreen()),
      );
      await tester.pumpAndSettle();

      final background = tester.widget<Image>(find.byType(Image));
      expect(background.fit, BoxFit.cover);
      expect(tester.getSize(find.byType(Image)), size);
      expect(tester.getTopLeft(find.byType(Image)), Offset.zero);

      expect(find.byType(ClipOval), findsNothing);
      expect(find.text('Buy From Lango'), findsOneWidget);
      final brandingRect = tester.getRect(
        find.byKey(const ValueKey('splash-branding')),
      );
      expect(brandingRect.center.dx, closeTo(size.width / 2, 0.01));
      expect(brandingRect.center.dy, closeTo(size.height / 2, 0.01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('splash automatically opens onboarding after three seconds',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, __) => const Scaffold(body: Text('Onboarding')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.byType(Image), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);
  });
}
