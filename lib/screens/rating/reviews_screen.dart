import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';

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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00B09B), // Premium Green
                Color(0xFF00A86B), // Deep Emerald
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30.r),
              bottomRight: Radius.circular(30.r),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),
              CircleAvatar(
                radius: 35.r,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(Icons.star_rounded, color: Colors.amber, size: 40.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                "$userName's Reviews",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Feedback from fellow travelers",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }

        final reviews = snapshot.data!.docs
            .map((doc) => ReviewModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        if (reviews.isEmpty) {
          return SliverFillRemaining(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined, size: 64.sp, color: AppColors.textHint),
                SizedBox(height: 16.h),
                Text(
                  'No reviews yet',
                  style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 12.h),
                  child: Column(
                    children: [
                      if (index == 0) ...[
                        _buildRatingSummary(reviews),
                        SizedBox(height: 20.h),
                      ],
                      _buildReviewCard(reviews[index]),
                    ],
                  ),
                );
              },
              childCount: reviews.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingSummary(List<ReviewModel> reviews) {
    double avgRating = reviews.isEmpty
        ? 0
        : reviews.fold(0.0, (acc, r) => acc + r.rating) / reviews.length;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 16.sp,
                  color: i < avgRating.floor() ? Colors.amber : AppColors.border,
                )),
              ),
              SizedBox(height: 4.h),
              Text('${reviews.length} reviews', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
            ],
          ),
          SizedBox(width: 30.w),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                int star = 5 - index;
                final count = reviews.where((r) => r.rating.round() == star).length;
                double percent = reviews.isEmpty ? 0 : count / reviews.length;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    children: [
                      Text('$star', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: AppColors.border.withValues(alpha: 0.3),
                            valueColor: const AlwaysStoppedAnimation(Colors.amber),
                            minHeight: 6.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(review.reviewerName[0].toUpperCase(), style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.reviewerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      Text(
                        "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}",
                        style: TextStyle(fontSize: 11.sp, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  size: 14.sp,
                  color: i < review.rating ? Colors.amber : AppColors.border,
                )),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textPrimary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
