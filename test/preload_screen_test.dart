import 'package:buy_from_lango/screens/preload_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('preload waits two seconds before opening splash',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const PreloadScreen()),
        GoRoute(
          path: '/splash',
          builder: (_, __) => const Scaffold(body: Text('Splash')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Splash'), findsOneWidget);
  });
}
