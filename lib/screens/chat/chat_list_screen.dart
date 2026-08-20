import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/shimmer_loading.dart';
import '../../models/booking_model.dart';
import '../../l10n/app_localizations.dart';
import 'ride_chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(child: Text(l10n?.pleaseLoginMessages ?? 'Please login to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium SliverAppBar ────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110.h,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.fromLTRB(20.w, 0, 0, 16.h),
              title: Text(
                l10n?.messages ?? 'Messages',
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
                child: Stack(
                  children: [
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              // Query bookings where user is either rider or driver and status is active/accepted
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(Filter.or(
                    Filter('riderUid', isEqualTo: user.uid),
                    Filter('driverUid', isEqualTo: user.uid),
                  ))
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Text('Error loading messages: ${snapshot.error}'),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmer();
                }

                // Filter out pending or cancelled bookings if necessary
                final bookings = snapshot.data?.docs.where((doc) {
                  final status = doc.get('status') as String? ?? '';
                  return status != 'pending' && status != 'cancelled' && status != 'rejected';
                }).toList() ?? [];

                if (bookings.isEmpty) {
                  return _buildEmptyState(context, isDark);
                }

                // Sort bookings by creation or ride date
                bookings.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as dynamic;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as dynamic;
                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  return 0;
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final bookingData = bookings[index].data() as Map<String, dynamic>;
                    final booking = BookingModel.fromMap(bookingData);
                    final isDriver = booking.driverUid == user.uid;
                    final otherName = isDriver ? booking.riderName : booking.driverName;
                    
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ride_chats')
                          .doc(booking.bookingId)
                          .snapshots(),
                      builder: (context, chatSnap) {
                        final chatData = chatSnap.data?.data() as Map<String, dynamic>?;
                        final lastMsg = chatData?['lastMessage'] ?? l10n?.tapToStartConversation ?? 'Tap to start conversation';
                        final lastTime = chatData?['lastMessageTime'] as Timestamp?;
                        final isMyMessage = chatData?['lastSenderId'] == user.uid;

                        return _buildChatTile(
                          context: context,
                          isDark: isDark,
                          booking: booking,
                          name: otherName.isEmpty ? (isDriver ? (l10n?.rider ?? 'Rider') : (l10n?.driver ?? 'Driver')) : otherName,
                          lastMsg: lastMsg,
                          time: lastTime != null ? _formatTime(lastTime) : '',
                          isMyMessage: isMyMessage,
                          isDriver: isDriver,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: List.generate(4, (i) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: ShimmerLoading(width: double.infinity, height: 80.h, borderRadius: 20.r),
        )),
      ),
    );
  }

  String _formatTime(Timestamp ts) {
    final date = ts.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }
    return '${date.day}/${date.month}';
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 400.h,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60.sp,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n?.noMessagesYet ?? 'No messages yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n?.conversationsWillAppearHere ?? 'Your ride conversations\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required bool isDark,
    required BookingModel booking,
    required String name,
    required String lastMsg,
    required String time,
    required bool isMyMessage,
    required bool isDriver,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideChatScreen(booking: booking, isDriver: isDriver),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.0 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                ),
                // Unread indicator badge
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ride_chats')
                      .doc(booking.bookingId)
                      .collection('messages')
                      .where('senderId', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (isMyMessage)
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Icon(Icons.done_all_rounded, size: 14.sp, color: AppColors.primary),
                        ),
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${booking.from} → ${booking.to}',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
