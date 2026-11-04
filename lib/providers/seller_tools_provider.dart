import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smart_response.dart';
import '../services/seller_tools_service.dart';

final sellerToolsServiceProvider =
    Provider<SellerToolsService>((ref) => SellerToolsService());

final smartResponsesProvider =
    FutureProvider.autoDispose.family<List<SmartResponseModel>, String>(
  (ref, userId) =>
      ref.watch(sellerToolsServiceProvider).getSmartResponses(userId),
);

final listingTagKeysProvider =
    FutureProvider.autoDispose.family<List<String>, (String, int)>(
  (ref, params) => ref.watch(sellerToolsServiceProvider).getListingTagKeys(
        userId: params.$1,
        listingId: params.$2,
      ),
);

final chatTagKeysProvider =
    FutureProvider.autoDispose.family<List<String>, (String, int)>(
  (ref, params) => ref.watch(sellerToolsServiceProvider).getChatTagKeys(
        userId: params.$1,
        threadId: params.$2,
      ),
);
