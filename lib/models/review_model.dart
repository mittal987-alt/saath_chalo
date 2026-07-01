import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String reviewerName;
  final String reviewedUserId;
  final String rideId;
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewedUserId,
    required this.rideId,
    required this.rating,
    required this.comment,
    this.tags = const [],
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
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(), // ✅ Server time
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
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: _parseDate(map['createdAt']), // ✅ Safe parse
    );
  }

  // ✅ Handles Timestamp, String & null safely
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // ✅ Copy with updated fields
  ReviewModel copyWith({
    String? reviewId,
    String? reviewerId,
    String? reviewerName,
    String? reviewedUserId,
    String? rideId,
    double? rating,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      rideId: rideId ?? this.rideId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ✅ Display helpers
  String get formattedRating => rating.toStringAsFixed(1);

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}