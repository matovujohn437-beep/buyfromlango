import 'package:buy_from_lango/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app frame fills phones and caps wide desktop content',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<double> renderAtWidth(double width) async {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ResponsiveAppFrame(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(
            body: SizedBox(
              key: Key('responsive-content'),
              width: double.infinity,
            ),
          ),
        ),
      );
      return tester.getSize(find.byKey(const Key('responsive-content'))).width;
    }

    expect(await renderAtWidth(390), 390);
    expect(await renderAtWidth(1800), ResponsiveBreakpoints.maxAppWidth);
  });
}
