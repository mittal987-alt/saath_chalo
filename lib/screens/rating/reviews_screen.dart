import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class ReviewsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ReviewsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$userName\'s Reviews'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('reviewedUserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary),
            );
          }

          // Dummy reviews for display
          final dummyReviews = [
            {
              'reviewerName': 'Priya Singh',
              'rating': 5.0,
              'comment': '😊 Friendly, ⏰ On Time, 🚗 Safe Driver. Amazing ride experience!',
              'time': '2 days ago',
            },
            {
              'reviewerName': 'Amit Kumar',
              'rating': 4.0,
              'comment': '🎵 Good Music, 🚘 Clean Car. Very comfortable ride!',
              'time': '1 week ago',
            },
            {
              'reviewerName': 'Rahul Sharma',
              'rating': 5.0,
              'comment': '👍 Recommended, 💬 Great Conversation. Will ride again!',
              'time': '2 weeks ago',
            },
          ];

          return Column(
            children: [
              // Rating Summary
              _buildRatingSummary(dummyReviews),

              // Reviews List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: dummyReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(dummyReviews[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingSummary(List<Map<String, dynamic>> reviews) {
    double avgRating = reviews.isEmpty
        ? 0
        : reviews.fold(0.0,
            (sum, r) => sum + (r['rating'] as double)) /
        reviews.length;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < avgRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${reviews.length} reviews',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          SizedBox(width: 24.w),

          // Rating Bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = reviews
                    .where((r) =>
                (r['rating'] as double).round() == star)
                    .length;
                final percent =
                reviews.isEmpty ? 0.0 : count / reviews.length;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    children: [
                      Text('$star',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                      SizedBox(width: 4.w),
                      Icon(Icons.star_rounded,
                          color: Colors.amber, size: 12.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: AppColors.border,
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                            minHeight: 6.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text('$count',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded,
                    color: AppColors.primary, size: 22.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['reviewerName'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review['time'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                      (i) => Icon(
                    i < (review['rating'] as double)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            review['comment'],
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}