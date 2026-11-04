import 'package:buy_from_lango/providers/listing_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location filters can be cleared when a parent selection changes', () {
    const state = ListingFeedState(
      districtId: 7,
      subcountyId: 12,
      parishId: 31,
    );

    final districtChanged = state.copyWith(
      districtId: 8,
      clearSubcounty: true,
      clearParish: true,
    );

    expect(districtChanged.districtId, 8);
    expect(districtChanged.subcountyId, isNull);
    expect(districtChanged.parishId, isNull);
  });

  test('clearing a subcounty also clears the selected parish', () {
    const state = ListingFeedState(
      districtId: 7,
      subcountyId: 12,
      parishId: 31,
    );

    final updated = state.copyWith(
      clearSubcounty: true,
      clearParish: true,
    );

    expect(updated.districtId, 7);
    expect(updated.subcountyId, isNull);
    expect(updated.parishId, isNull);
  });
}
