import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _markAllRead() async {
    if (uid == null) return;
    await _firebaseService.markAllNotificationsRead(uid!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'ride_request':
        return Icons.directions_car_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'message':
        return Icons.chat_rounded;
      case 'ride_complete':
        return Icons.check_circle_rounded;
      case 'rating':
        return Icons.star_rounded;
      case 'tip':
        return Icons.tips_and_updates_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'ride_request':
        return const Color(0xFF00A86B);
      case 'payment':
        return const Color(0xFF00C853);
      case 'message':
        return const Color(0xFF1565C0);
      case 'ride_complete':
        return const Color(0xFF00C853);
      case 'rating':
        return const Color(0xFFFFC107);
      case 'tip':
        return const Color(0xFFFF6B35);
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Now';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const Scaffold(body: Center(child: Text('Please login')));

    return StreamBuilder<QuerySnapshot>(
      stream: _firebaseService.getNotifications(uid!),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.where((doc) => !(doc.data() as Map<String, dynamic>)['isRead']).length;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Notifications'),
                if (unreadCount > 0) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            actions: [
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
                TextButton(
                  onPressed: _markAllRead,
                  child: Text(
                    'Mark All Read',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
          body: !snapshot.hasData
              ? const Center(child: CircularProgressIndicator())
              : snapshot.data!.docs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildNotificationCard(doc.id, data);
                      },
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 64.sp, color: AppColors.border),
          SizedBox(height: 16.h),
          Text(
            'No notifications yet!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'We will notify you about\nride requests & updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String docId, Map<String, dynamic> data) {
    final bool isRead = data['isRead'] ?? false;
    final String? type = data['type'];
    final Color color = _getColor(type);

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_rounded,
            color: AppColors.white, size: 24.sp),
      ),
      onDismissed: (direction) {
        _firebaseService.deleteNotification(docId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification dismissed')),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _firebaseService.markNotificationRead(docId);
          }
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.white
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.2),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(type),
                  color: color,
                  size: 24.sp,
                ),
              ),

              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Notification',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(data['timestamp'] as Timestamp?),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isRead
                                ? AppColors.textHint
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      data['body'] ?? '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // Unread dot
              if (!isRead)
                Container(
                  width: 8.w,
                  height: 8.w,
                  margin: EdgeInsets.only(top: 4.h),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}