import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review.dart';
import '../supabase_config.dart';

class ReviewService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    final response = await _client
        .from('reviews')
        .select('id, reviewer_id, seller_id, rating, comment, created_at')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map(
          (row) => ReviewModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> createReview({
    required String reviewerId,
    required String sellerId,
    required int rating,
    required String comment,
  }) async {
    if (reviewerId == sellerId) {
      throw ArgumentError('You cannot review your own profile.');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Must be from 1 to 5.');
    }
    await _client.from('reviews').insert({
      'reviewer_id': reviewerId,
      'seller_id': sellerId,
      'rating': rating,
      'comment': comment.trim().isEmpty ? null : comment.trim(),
    });
  }
}
