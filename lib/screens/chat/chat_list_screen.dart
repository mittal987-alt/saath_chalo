import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/shimmer_loading.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                'Messages',
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
                    Positioned(
                      bottom: -25,
                      right: 60.w,
                      child: Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
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
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox(
                    height: 500.h,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: AppColors.background.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 80.sp,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Once you book or offer a ride,\nyour chats will appear here.',
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

                final chatDocs = snapshot.data!.docs;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                      child: Text(
                        '${chatDocs.length} Conversation${chatDocs.length > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                      itemCount: chatDocs.length,
                      itemBuilder: (context, index) {
                        final chatData = chatDocs[index].data() as Map<String, dynamic>;
                        final rideId = chatDocs[index].id;

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('chats')
                              .doc(rideId)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, msgSnapshot) {
                            String lastMsg = 'No messages yet';
                            String time = '';

                            if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
                              final msgData = msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                              lastMsg = msgData['text'] ?? '';
                              final ts = msgData['timestamp'] as Timestamp?;
                              if (ts != null) {
                                final date = ts.toDate();
                                final hour = date.hour.toString().padLeft(2, '0');
                                final min = date.minute.toString().padLeft(2, '0');
                                time = '$hour:$min';
                              }
                            }

                            return _buildChatTile(
                              context: context,
                              isDark: isDark,
                              rideId: rideId,
                              name: 'Ride Chat: ${rideId.substring(0, 6).toUpperCase()}',
                              lastMsg: lastMsg,
                              time: time,
                              isMyMessage: msgSnapshot.hasData &&
                                  msgSnapshot.data!.docs.isNotEmpty &&
                                  (msgSnapshot.data!.docs.first.data() as Map<String, dynamic>)['senderId'] == user?.uid,
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required bool isDark,
    required String rideId,
    required String name,
    required String lastMsg,
    required String time,
    required bool isMyMessage,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(rideId: rideId, otherUserName: name),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
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
            // ── Avatar with gradient ring ─────────────────
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F9D58), Color(0xFF34A853)],
                ),
              ),
              child: CircleAvatar(
                radius: 24.r,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
                child: Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // ── Chat Info ────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                            fontWeight: FontWeight.w500,
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
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 14.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontStyle: lastMsg == 'No messages yet' ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}