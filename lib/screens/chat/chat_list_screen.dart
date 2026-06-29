import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .snapshots(), // This is a simplification. Ideally, user-specific chats.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64.sp, color: AppColors.textHint),
                  SizedBox(height: 16.h),
                  const Text('No messages yet'),
                ],
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
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
                  String lastMsg = "No messages";
                  String time = "";
                  
                  if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
                    final msgData = msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    lastMsg = msgData['text'] ?? "";
                    final ts = msgData['timestamp'] as Timestamp?;
                    if (ts != null) {
                      final date = ts.toDate();
                      time = "${date.hour}:${date.minute}";
                    }
                  }

                  return _buildChatTile(context, {
                    'name': 'Ride Chat: ${rideId.substring(0, 5)}...', // Placeholder for ride name
                    'lastMsg': lastMsg,
                    'time': time,
                    'unread': 0,
                    'rideId': rideId,
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(
      BuildContext context, Map<String, dynamic> chat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              rideId: chat['rideId'],
              otherUserName: chat['name'],
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 28.sp),
                ),
                // Online dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 12.w),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'],
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        chat['time'],
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: chat['unread'] > 0
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat['lastMsg'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: chat['unread'] > 0
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: chat['unread'] > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat['unread'] > 0)
                        Container(
                          padding: EdgeInsets.all(5.w),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chat['unread']}',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
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