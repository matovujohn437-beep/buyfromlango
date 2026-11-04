import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buy_from_lango/theme.dart';

void main() {
  test('Lango theme uses accessible green and orange brand colors', () {
    expect(AppColors.primary, const Color(0xFF2E7D32));
    expect(
      AppColors.primary.computeLuminance(),
      lessThanOrEqualTo(0.18),
    );
    expect(AppColors.accent, const Color(0xFFC17A3A));
  });
}
