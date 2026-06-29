class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String reviewerName;
  final String reviewedUserId;
  final String rideId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewedUserId,
    required this.rideId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewedUserId': reviewedUserId,
      'rideId': rideId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewedUserId: map['reviewedUserId'] ?? '',
      rideId: map['rideId'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}