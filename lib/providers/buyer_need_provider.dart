import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/buyer_need.dart';
import '../services/buyer_need_service.dart';

final buyerNeedServiceProvider =
    Provider<BuyerNeedService>((ref) => BuyerNeedService());

final activeBuyerNeedsProvider = FutureProvider<List<BuyerNeedModel>>((ref) {
  return ref.watch(buyerNeedServiceProvider).getActiveNeeds();
});
