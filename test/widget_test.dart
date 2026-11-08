import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buy_from_lango/theme.dart';

void main() {
  test('Lango theme uses its agricultural palette in light and dark modes', () {
    expect(AppColors.primary, const Color(0xFF087A35));
    expect(AppColors.primaryDark, const Color(0xFF07552D));
    expect(AppColors.accent, const Color(0xFFF5B800));
    expect(AppColors.background, const Color(0xFFF5F8F2));
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
    expect(AppTheme.dark.colorScheme.surface, AppColors.darkSurface);
  });
}
