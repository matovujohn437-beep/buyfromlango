import 'package:buy_from_lango/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listing parses and serializes job and service fields', () {
    final listing = ListingModel.fromJson({
      'id': 42,
      'user_id': 'seller-id',
      'category_id': 'jobs',
      'title': 'Harvest worker',
      'workers_needed': 5,
      'service_type': 'Harvest worker',
    });

    expect(listing.workersNeeded, 5);
    expect(listing.serviceType, 'Harvest worker');
    expect(listing.toJson()['workers_needed'], 5);
    expect(listing.toJson()['service_type'], 'Harvest worker');
  });
}
