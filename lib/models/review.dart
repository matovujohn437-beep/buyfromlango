import 'json_helpers.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.sellerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final int id;
  final String reviewerId;
  final String sellerId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: JsonReader.intValue(json, 'id', defaultValue: 0) ?? 0,
        reviewerId: JsonReader.string(json, 'reviewer_id'),
        sellerId: JsonReader.string(json, 'seller_id'),
        rating: JsonReader.intValue(json, 'rating', defaultValue: 0) ?? 0,
        comment: json['comment']?.toString(),
        createdAt: JsonReader.dateTime(json, 'created_at'),
      );
}
