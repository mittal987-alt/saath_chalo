import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/firebase_services.dart';
import '../ai/ai_assistant_screen.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await _db
        .collection('chats')
        .doc(widget.rideId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': _currentUser?.uid,
      'senderName': _currentUser?.displayName ?? 'User',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send Notification to the other user
    final rideDoc = await _db.collection('rides').doc(widget.rideId).get();
    final driverUid = rideDoc.data()?['driverUid'];
    // In a real app, you'd track the rider UIDs in the ride document.
    // For now, if current user is rider, send to driver.
    if (_currentUser?.uid != driverUid) {
      FirebaseService().sendNotification(
        toUid: driverUid,
        title: 'New Message from ${widget.otherUserName}',
        body: text,
        type: 'message',
        data: {'rideId': widget.rideId},
      );
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              child: Icon(Icons.person_rounded,
                  color: AppColors.white, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Add between map icon and avatar
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AIAssistantScreen()),
            ),
            icon: const Icon(
              Icons.smart_toy_rounded,
              color: AppColors.white,
              size: 28,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chats')
                  .doc(widget.rideId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 60.sp, color: AppColors.border),
                        SizedBox(height: 16.h),
                        Text(
                          'No messages yet!\nSay Hi 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                    messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUser?.uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 16.sp),
            ),
            SizedBox(width: 8.w),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                  bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg['senderName'] ?? 'User',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  if (!isMe) SizedBox(height: 2.h),
                  Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isMe ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatTime(msg['timestamp']),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isMe
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            SizedBox(width: 8.w),
            Icon(Icons.done_all_rounded,
                size: 14.sp, color: AppColors.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji Button
            GestureDetector(
              onTap: () {},
              child: Icon(Icons.emoji_emotions_rounded,
                  color: AppColors.textHint, size: 24.sp),
            ),

            SizedBox(width: 8.w),

            // Text Field
            Expanded(
              child: Container(
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Attachment Button
            GestureDetector(
              onTap: () {},
              child: Icon(Icons.attach_file_rounded,
                  color: AppColors.textHint, size: 24.sp),
            ),

            SizedBox(width: 8.w),

            // Send Button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send_rounded,
                    color: AppColors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } catch (e) {
      return '';
    }
  }
}