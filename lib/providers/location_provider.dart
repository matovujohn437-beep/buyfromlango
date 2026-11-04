import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/district.dart';
import '../models/parish.dart';
import '../models/subcounty.dart';
import '../services/geo_service.dart';

final geoServiceProvider = Provider<GeoService>((ref) => GeoService());

final districtsProvider = FutureProvider<List<District>>((ref) async {
  return ref.read(geoServiceProvider).getDistricts();
});

final subcountiesProvider =
    FutureProvider.family<List<Subcounty>, int>((ref, districtId) async {
  return ref.read(geoServiceProvider).getSubcounties(districtId: districtId);
});

final parishesProvider =
    FutureProvider.family<List<Parish>, int>((ref, subcountyId) async {
  return ref.read(geoServiceProvider).getParishes(subcountyId: subcountyId);
});
