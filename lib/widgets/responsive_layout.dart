import 'package:flutter/material.dart';

import '../theme.dart';

class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double compact = 600;
  static const double expanded = 840;
  static const double wide = 1200;
  static const double maxAppWidth = 1440;
}

class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.clamp(0.0, ResponsiveBreakpoints.maxAppWidth);
        return ColoredBox(
          color: AppColors.background,
          child: Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1100,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
