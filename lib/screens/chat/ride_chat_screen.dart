import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';

class RideChatScreen extends StatefulWidget {
  final BookingModel booking;
  final bool isDriver;

  const RideChatScreen({
    super.key,
    required this.booking,
    required this.isDriver,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Chat ID is always booking ID — unique per ride+rider pair
  String get _chatId => widget.booking.bookingId;

  String get _otherPersonName => widget.isDriver
      ? widget.booking.riderName
      : widget.booking.driverName;

  String get _myName =>
      _user?.displayName ??
          (widget.isDriver
              ? widget.booking.driverName
              : widget.booking.riderName);

  // Quick reply suggestions
  final List<String> _quickReplies = [
    '👍 On my way!',
    '⏰ 5 minutes away',
    '📍 I am at the pickup point',
    '🚗 I have arrived',
    '✅ Got it!',
    '🙏 Thank you',
    '❓ Where are you?',
    '⌛ Please wait',
  ];

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final messages = await _db
        .collection('ride_chats')
        .doc(_chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: _user?.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    await _db
        .collection('ride_chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': _user?.uid ?? '',
      'senderName': _myName,
      'isDriver': widget.isDriver,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message on chat doc
    await _db.collection('ride_chats').doc(_chatId).set({
      'bookingId': _chatId,
      'rideId': widget.booking.rideId,
      'driverUid': widget.booking.driverUid,
      'driverName': widget.booking.driverName,
      'riderUid': widget.booking.riderUid,
      'riderName': widget.booking.riderName,
      'participants': [widget.booking.driverUid, widget.booking.riderUid],
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': _user?.uid ?? '',
    }, SetOptions(merge: true));

    // Send notification to the other person
    final String otherUid = widget.isDriver ? widget.booking.riderUid : widget.booking.driverUid;
    await _db.collection('notifications').add({
      'toUid': otherUid,
      'title': 'New Message from $_myName 💬',
      'body': text.trim(),
      'type': 'chat_message',
      'data': {
        'bookingId': _chatId,
        'senderId': _user?.uid,
      },
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.white.withOpacity(0.2),
              child: Icon(
                widget.isDriver
                    ? Icons.person_rounded
                    : Icons.directions_car_rounded,
                color: AppColors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherPersonName.isEmpty
                        ? (widget.isDriver ? 'Rider' : 'Driver')
                        : _otherPersonName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    '${widget.booking.from} → ${widget.booking.to}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Phone call button
          IconButton(
            onPressed: () async {
              String phone = '';
              if (widget.isDriver) {
                phone = widget.booking.riderPhone;
              } else {
                final doc = await FirebaseFirestore.instance.collection('users').doc(widget.booking.driverUid).get();
                phone = doc.data()?['phone'] ?? '';
              }
              
              if (phone.isNotEmpty) {
                final Uri telUri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not available')));
                }
              }
            },
            icon: const Icon(Icons.call_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Ride info banner
          _buildRideInfoBanner(),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('ride_chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return _buildEmptyChat();
                }

                // Mark new messages as read
                _markMessagesAsRead();

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 8.h),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>? ?? {};
                    final isMe = msg['senderId'] == _user?.uid;
                    
                    // Logic for date separator
                    bool showDateSeparator = false;
                    String dateText = '';
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevMsg = messages[index - 1].data() as Map<String, dynamic>;
                      final prevTime = (prevMsg['timestamp'] as Timestamp?)?.toDate();
                      final currTime = (msg['timestamp'] as Timestamp?)?.toDate();
                      
                      if (prevTime != null && currTime != null) {
                        if (prevTime.day != currTime.day || prevTime.month != currTime.month || prevTime.year != currTime.year) {
                          showDateSeparator = true;
                        }
                      }
                    }

                    if (showDateSeparator) {
                      final date = (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final now = DateTime.now();
                      if (date.day == now.day && date.month == now.month && date.year == now.year) {
                        dateText = 'Today';
                      } else if (date.day == now.subtract(const Duration(days: 1)).day) {
                        dateText = 'Yesterday';
                      } else {
                        dateText = '${date.day}/${date.month}/${date.year}';
                      }
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.textHint.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _buildMessageBubble(msg, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Quick replies
          _buildQuickReplies(),

          // Input box
          _buildInputBox(),
        ],
      ),
    );
  }

  Widget _buildRideInfoBanner() {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route_rounded,
              color: AppColors.primary, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '${widget.booking.from} → ${widget.booking.to}  •  ${widget.booking.seatsBooked} seat(s)  •  ₹${widget.booking.totalPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              widget.booking.status.toUpperCase(),
              style: TextStyle(
                fontSize: 9.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 40.sp, color: AppColors.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'No messages yet!',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Say hi to your ${widget.isDriver ? 'rider' : 'driver'} 👋',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => _sendMessage(
                '👋 Hi! I\'m your ${widget.isDriver ? 'driver' : 'rider'} for today!'),
            icon: const Icon(Icons.waving_hand_rounded),
            label: const Text('Say Hello!'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> msg, bool isMe) {
    final String text = msg['text'] ?? '';
    final bool isRead = msg['isRead'] ?? false;
    final timestamp = msg['timestamp'];

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
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                msg['isDriver'] == true
                    ? Icons.directions_car_rounded
                    : Icons.person_rounded,
                color: AppColors.primary,
                size: 14.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 10.h),
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
                    color: Colors.black.withOpacity(0.06),
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
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        msg['senderName'] ?? '',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isMe
                          ? AppColors.white
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isMe
                              ? AppColors.white.withOpacity(0.7)
                              : AppColors.textHint,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 4.w),
                        Icon(
                          isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 12.sp,
                          color: isRead
                              ? Colors.lightBlueAccent
                              : AppColors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 36.h,
      margin: EdgeInsets.only(bottom: 4.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickReplies[index]),
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Text(
                _quickReplies[index],
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBox() {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Emoji button
            GestureDetector(
              onTap: () {},
              child: Icon(Icons.emoji_emotions_rounded,
                  color: AppColors.textHint, size: 24.sp),
            ),

            SizedBox(width: 8.w),

            // Text field
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (text) => _sendMessage(text),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Send button
            GestureDetector(
              onTap: () => _sendMessage(_messageController.text),
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
      DateTime dt;
      if (timestamp is Timestamp) {
        dt = timestamp.toDate();
      } else {
        return '';
      }
      final now = DateTime.now();
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$min';

      // If today, just show time. If not, show date + time.
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return timeStr;
      }
      return '${dt.day}/${dt.month} $timeStr';
    } catch (_) {
      return '';
    }
  }
}