import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../services/moderation_service.dart';
import '../../services/firebase_services.dart';
import '../profile/report_issue_screen.dart';

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

class _RatingScreenState extends State<RatingScreen>
    with SingleTickerProviderStateMixin {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late AnimationController _starAnimController;

  final List<String> _tags = [
    '😊 Friendly',
    '⏰ On Time',
    '🚗 Safe Driver',
    '🎵 Good Music',
    '💬 Great Talk',
    '🚘 Clean Car',
    '🗺️ Good Route',
    '👍 Recommended',
  ];

  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _starAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _starAnimController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty && _selectedTags.isEmpty) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a comment or select at least one tag!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          margin: EdgeInsets.all(16.w),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final reviewId = DateTime.now().millisecondsSinceEpoch.toString();
      final comment = _commentController.text.trim();

      final textToModerate = _selectedTags.isNotEmpty
          ? '${_selectedTags.join(', ')}. $comment'
          : comment;
      final moderationResult = ModerationService.moderateContent(textToModerate);

      final review = ReviewModel(
        reviewId: reviewId,
        reviewerId: _user?.uid ?? '',
        reviewerName: _user?.displayName ?? 'User',
        reviewedUserId: widget.driverUid,
        rideId: widget.rideId,
        rating: _rating,
        comment: comment,
        tags: List.from(_selectedTags),
        createdAt: DateTime.now(),
        status: moderationResult['status'],
        moderationNote: moderationResult['note'],
      );

      await _db.collection('reviews').doc(reviewId).set(review.toMap());

      if (review.status == 'flagged') {
        await FirebaseService().sendNotification(
          toUid: 'admin_panel',
          title: 'Review Flagged for Moderation 🛡️',
          body: 'A review by ${review.reviewerName} was flagged: ${review.moderationNote}',
          type: 'admin_moderation',
          data: {'reviewId': reviewId},
        );
      }

      await _updateDriverRating();

      await _db.collection('users').doc(widget.driverUid).update({
        'totalCo2Saved': FieldValue.increment(2.5),
      });

      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16.w),
        ),
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
      final avgRating = totalRating / reviews.docs.length;
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_submitted) return _buildSuccessScreen(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient AppBar ───────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 100.h,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20.w, 0, 0, 16.h),
              title: Text(
                'Rate Your Ride',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF1A3C34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  _buildDriverCard(isDark),
                  SizedBox(height: 16.h),
                  _buildStarRating(isDark),
                  SizedBox(height: 16.h),
                  _buildQuickTags(isDark),
                  SizedBox(height: 16.h),
                  _buildCommentBox(isDark),
                  SizedBox(height: 24.h),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isLoading
                              ? [AppColors.textHint, AppColors.textHint]
                              : AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(_isLoading ? 0 : 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                        ),
                        icon: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Submitting...' : 'Submit Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Report link
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportIssueScreen(
                          reportedId: widget.driverUid,
                          type: 'user',
                          metadata: {'rideId': widget.rideId},
                        ),
                      ),
                    ),
                    icon: Icon(Icons.flag_rounded, color: AppColors.error, size: 16.sp),
                    label: Text(
                      'Report an issue with this driver',
                      style: TextStyle(color: AppColors.error, fontSize: 13.sp),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'How was your ride with',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),

          // Driver avatar
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
              ),
            ),
            child: CircleAvatar(
              radius: 40.r,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 44.sp),
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            widget.driverName,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 10.h),

          // Route pill
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radio_button_checked, size: 10.sp, color: AppColors.primary),
                SizedBox(width: 6.w),
                Text(
                  widget.from,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                Icon(Icons.arrow_forward_rounded, size: 12.sp, color: AppColors.primary),
                Text(
                  widget.to,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.location_on_rounded, size: 10.sp, color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _getRatingLabel(),
              key: ValueKey(_rating),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: _getRatingColor(),
                letterSpacing: -0.5,
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Star buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isSelected = index < _rating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rating = index + 1.0);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: isSelected ? 46.sp : 38.sp,
                  ),
                ),
              );
            }),
          ),

          SizedBox(height: 12.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor', style: TextStyle(fontSize: 11.sp, color: AppColors.textHint, fontWeight: FontWeight.w500)),
              Text('Excellent', style: TextStyle(fontSize: 11.sp, color: AppColors.textHint, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTags(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'What did you like?',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 6.w),
              Text('👍', style: TextStyle(fontSize: 15.sp)),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Select all that apply',
            style: TextStyle(fontSize: 11.sp, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 10.h,
            children: _tags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
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
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.background),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  Widget _buildCommentBox(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.0 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add a comment',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 6.w),
              Text('✍️', style: TextStyle(fontSize: 15.sp)),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Optional — help others know what to expect',
            style: TextStyle(fontSize: 11.sp, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 200,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 14.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Share your experience with other riders...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.sp),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: EdgeInsets.all(14.w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie success animation
                SizedBox(
                  height: 200.h,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(30.w),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 100.sp,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                Text(
                  'Review Submitted! 🎉',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),

                SizedBox(height: 10.h),

                Text(
                  'Thank you for rating ${widget.driverName}.\nYour review helps the community!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 24.h),

                // Star display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 36.sp,
                  )),
                ),

                SizedBox(height: 40.h),

                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.primaryGradient),
                      borderRadius: BorderRadius.circular(18.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                      ),
                      child: Text('Done', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}