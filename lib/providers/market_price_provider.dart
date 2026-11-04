import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/market_price.dart';
import '../services/market_price_service.dart';

final marketPriceServiceProvider =
    Provider<MarketPriceService>((ref) => MarketPriceService());

final marketPricesProvider =
    FutureProvider.family<List<MarketPriceModel>, int?>((ref, districtId) {
  return ref
      .watch(marketPriceServiceProvider)
      .getMarketPrices(districtId: districtId);
});
