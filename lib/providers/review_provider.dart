import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final sellerReviewsProvider =
    FutureProvider.family<List<ReviewModel>, String>((ref, sellerId) {
  return ref.watch(reviewServiceProvider).getReviewsForSeller(sellerId);
});
