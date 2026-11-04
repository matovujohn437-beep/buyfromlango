import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/banner.dart';
import '../services/banner_service.dart';

final bannerServiceProvider = Provider<BannerService>((ref) => BannerService());

final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  return ref.read(bannerServiceProvider).getBanners();
});

final bannersStreamProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.read(bannerServiceProvider).watchBanners();
});
