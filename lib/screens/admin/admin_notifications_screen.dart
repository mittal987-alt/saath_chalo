import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  String _selectedTarget = 'All Users';

  final List<String> _targets = [
    'All Users',
    'Drivers Only',
    'Riders Only',
  ];

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty ||
        _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill title and message!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'target': _selectedTarget,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });

      // Also save to notifications collection for all users
      final users = await FirebaseFirestore.instance
          .collection('users')
          .get();
      for (var user in users.docs) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'toUid': user.id,
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _titleController.clear();
      _bodyController.clear();
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent to all users!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send Notifications'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send Notification Card
            Container(
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
                    '📢 Send Notification',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Target
                  Text('Send To',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTarget,
                        isExpanded: true,
                        items: _targets
                            .map((t) => DropdownMenuItem(
                            value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setState(
                                () => _selectedTarget = val!),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Title
                  Text('Title',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Notification title',
                      prefixIcon:
                      Icon(Icons.title_rounded),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Message
                  Text('Message',
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  SizedBox(height: 8.h),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write your message here...',
                      prefixIcon:
                      Icon(Icons.message_rounded),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _sendNotification,
                    icon: _isLoading
                        ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2),
                    )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isLoading
                        ? 'Sending...'
                        : 'Send to $_selectedTarget'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Previous Notifications
            Text(
              'Sent Notifications',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('admin_notifications')
                  .orderBy('sentAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No notifications sent yet!',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp)),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: 10.h),
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                        BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color:
                            Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                                Icons.notifications_rounded,
                                color: AppColors.primary,
                                size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight:
                                    FontWeight.w600,
                                    color:
                                    AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  data['body'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors
                                        .textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                                Text(
                                  'To: ${data['target']}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}