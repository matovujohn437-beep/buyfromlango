import 'package:buy_from_lango/constants/listing_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each main listing category offers only appropriate units', () {
    expect(listingUnitsForCategory('crops'), contains('tonne'));
    expect(listingUnitsForCategory('crops'), isNot(contains('job')));
    expect(listingUnitsForCategory('livestock'), contains('head'));
    expect(listingUnitsForCategory('livestock'), isNot(contains('tonne')));
    expect(listingUnitsForCategory('services'), contains('service'));
    expect(listingUnitsForCategory('services'), isNot(contains('job')));
    expect(listingUnitsForCategory('jobs'), contains('job'));
    expect(listingUnitsForCategory('jobs'), isNot(contains('tonne')));
  });

  test('legacy and unknown categories have safe unit options', () {
    expect(
        listingUnitsForCategory('produce'), listingUnitsForCategory('crops'));
    expect(listingUnitsForCategory('unknown'), isEmpty);
    expect(listingUnitsForCategory(null), isEmpty);
  });
}
