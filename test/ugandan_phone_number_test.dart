import 'package:buy_from_lango/utils/ugandan_phone_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ugandan phone numbers', () {
    test('normalizes supported local formats to the canonical format', () {
      expect(normalizeUgandanPhoneNumber('+256700123456'), '+256700123456');
      expect(normalizeUgandanPhoneNumber('256700123456'), '+256700123456');
      expect(normalizeUgandanPhoneNumber('0700123456'), '+256700123456');
      expect(normalizeUgandanPhoneNumber('+256 700 123 456'), '+256700123456');
    });

    test('rejects invalid numbers and canonical validation is strict', () {
      expect(normalizeUgandanPhoneNumber('700123456'), isNull);
      expect(normalizeUgandanPhoneNumber('+25670012345'), isNull);
      expect(normalizeUgandanPhoneNumber('+255700123456'), isNull);
      expect(isCanonicalUgandanPhoneNumber('+256700123456'), isTrue);
      expect(isCanonicalUgandanPhoneNumber('0700123456'), isFalse);
    });
  });
}
