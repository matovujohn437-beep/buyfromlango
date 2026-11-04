String? normalizeUgandanPhoneNumber(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  final canonical = switch (digits) {
    final value when RegExp(r'^\+256[0-9]{9}$').hasMatch(value) => value,
    final value when RegExp(r'^256[0-9]{9}$').hasMatch(value) => '+$value',
    final value when RegExp(r'^0[0-9]{9}$').hasMatch(value) =>
      '+256${value.substring(1)}',
    _ => null,
  };
  return canonical;
}

bool isCanonicalUgandanPhoneNumber(String? value) =>
    value != null && RegExp(r'^\+256[0-9]{9}$').hasMatch(value);
