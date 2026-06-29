import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';

class RatingScreen extends StatefulWidget {
  final String rideId;
  final String driverName;
  final String driverUid;
  final String from;
  final String to;

  const RatingScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.driverUid,
    required this.from,
    required this.to,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Quick review tags
  final List<String> _tags = [
    '😊 Friendly',
    '⏰ On Time',
    '🚗 Safe Driver',
    '🎵 Good Music',
    '💬 Great Conversation',
    '🚘 Clean Car',
    '🗺️ Good Route',
    '👍 Recommended',
  ];

  final List<String> _selectedTags = [];

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty && _selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment or select tags!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final reviewId = DateTime.now().millisecondsSinceEpoch.toString();
      final comment = _selectedTags.isNotEmpty
          ? '${_selectedTags.join(', ')}. ${_commentController.text}'
          : _commentController.text;

      final review = ReviewModel(
        reviewId: reviewId,
        reviewerId: _user?.uid ?? '',
        reviewerName: _user?.displayName ?? 'User',
        reviewedUserId: widget.driverUid,
        rideId: widget.rideId,
        rating: _rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Save review
      await _db
          .collection('reviews')
          .doc(reviewId)
          .set(review.toMap());

      // Update driver's average rating
      await _updateDriverRating();

      setState(() => _isLoading = false);

      // Show success
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded,
                    color: Colors.amber, size: 80.sp),
                SizedBox(height: 16.h),
                Text(
                  'Review Submitted!',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Thank you for rating ${widget.driverName}!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 28.sp,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _updateDriverRating() async {
    final reviews = await _db
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: widget.driverUid)
        .get();

    if (reviews.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data()['rating'] ?? 5.0).toDouble();
      }
      double avgRating = totalRating / reviews.docs.length;

      await _db.collection('users').doc(widget.driverUid).update({
        'rating': double.parse(avgRating.toStringAsFixed(1)),
        'totalReviews': reviews.docs.length,
      });
    }
  }

  String _getRatingLabel() {
    if (_rating >= 5) return 'Excellent! 🤩';
    if (_rating >= 4) return 'Very Good! 😊';
    if (_rating >= 3) return 'Good 🙂';
    if (_rating >= 2) return 'Fair 😐';
    return 'Poor 😞';
  }

  Color _getRatingColor() {
    if (_rating >= 4) return AppColors.success;
    if (_rating >= 3) return Colors.amber;
    return AppColors.error;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Your Ride'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Driver Card
            _buildDriverCard(),

            SizedBox(height: 16.h),

            // Star Rating
            _buildStarRating(),

            SizedBox(height: 16.h),

            // Quick Tags
            _buildQuickTags(),

            SizedBox(height: 16.h),

            // Comment Box
            _buildCommentBox(),

            SizedBox(height: 24.h),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitReview,
              icon: _isLoading
                  ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded),
              label: Text(
                  _isLoading ? 'Submitting...' : 'Submit Review'),
            ),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
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
        children: [
          Text(
            'How was your ride?',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          CircleAvatar(
            radius: 36.r,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person_rounded,
                color: AppColors.primary, size: 42.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.driverName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${widget.from} → ${widget.to}',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Container(
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
      child: Column(
        children: [
          Text(
            _getRatingLabel(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: _getRatingColor(),
            ),
          ),
          SizedBox(height: 16.h),

          // Star Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: index < _rating ? 44.sp : 38.sp,
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint)),
              Text('Excellent',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags() {
    return Container(
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
          Text(
            'What did you like? 👍',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBox() {
    return Container(
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
          Text(
            'Add a Comment ✍️',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText:
              'Share your experience with other riders...',
              hintStyle: TextStyle(
                  color: AppColors.textHint, fontSize: 13.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide:
                const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide:
                const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 2),
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ],
      ),
    );
  }
}