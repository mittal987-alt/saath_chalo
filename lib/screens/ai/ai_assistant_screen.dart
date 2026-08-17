import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ai_assistant_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _conversationHistory = [];
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'text':
      '🙏 Namaste! I am SaathChalo AI!\n\nI can help you with:\n\n🗺️ Best carpool routes\n💰 Fare calculations\n🚦 Best travel times\n🛡️ Safety tips\n💬 Carpooling advice\n\nHow can I help you today?',
      'isUser': false,
      'isError': false,
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'isError': false,
      });
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final db = FirebaseFirestore.instance;

      Map<String, dynamic>? userData;
      List<Map<String, dynamic>> bookings = [];
      List<Map<String, dynamic>> offeredRides = [];
      List<Map<String, dynamic>> reviews = [];
      List<Map<String, dynamic>> payments = [];
      List<Map<String, dynamic>> alerts = [];
      List<Map<String, dynamic>> reports = [];
      List<Map<String, dynamic>> notifications = [];
      List<Map<String, dynamic>> sosAlerts = [];
      List<Map<String, dynamic>> globalRides = [];
      Map<String, dynamic>? safetySettings;

      if (user != null) {
        final userDoc = await db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userData = userDoc.data();
        }

        // Safety Settings
        final safetyDoc = await db.collection('users').doc(user.uid).collection('settings').doc('safety').get();
        safetySettings = safetyDoc.data();

        // Notifications
        final notifSnapshot = await db
            .collection('notifications')
            .where('toUid', isEqualTo: user.uid)
            .limit(10)
            .get();
        notifications = notifSnapshot.docs.map((doc) => doc.data()).toList();

        // SOS Alerts
        final sosSnapshot = await db
            .collection('sos_alerts')
            .where('uid', isEqualTo: user.uid)
            .limit(5)
            .get();
        sosAlerts = sosSnapshot.docs.map((doc) => doc.data()).toList();

        // Global Active Rides (Snapshot for AI to see availability)
        final globalRideSnapshot = await db
            .collection('rides')
            .where('status', isEqualTo: 'active')
            .limit(10)
            .get();
        globalRides = globalRideSnapshot.docs.map((doc) => doc.data()).toList();

        final bookingSnapshot = await db
            .collection('bookings')
            .where('riderUid', isEqualTo: user.uid)
            .limit(5)
            .get();
        bookings = bookingSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

        final rideSnapshot = await db
            .collection('rides')
            .where('driverUid', isEqualTo: user.uid)
            .limit(5)
            .get();
        offeredRides = rideSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

        final reviewSnapshot = await db
            .collection('reviews')
            .where('reviewerId', isEqualTo: user.uid)
            .limit(5)
            .get();
        reviews = reviewSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

        final paymentSnapshot = await db
            .collection('payments')
            .where('userId', isEqualTo: user.uid)
            .limit(5)
            .get();
        payments = paymentSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

        final alertSnapshot = await db
            .collection('ride_alerts')
            .where('uid', isEqualTo: user.uid)
            .limit(5)
            .get();
        alerts = alertSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();

        final reportSnapshot = await db
            .collection('reports')
            .where('reporterId', isEqualTo: user.uid)
            .limit(3)
            .get();
        reports = reportSnapshot.docs
            .map((doc) => Map<String, dynamic>.from(doc.data()))
            .toList();
      }

      final aiText = await AIAssistantService.askAssistant(
        message: text,
        history: _conversationHistory,
        user: userData != null
            ? {
                'name': userData['name'] ?? user?.displayName ?? 'User',
                'totalRides': userData['totalRides'] ?? 0,
                'totalMoneySaved': userData['totalMoneySaved'] ?? 0.0,
                'totalCo2Saved': userData['totalCo2Saved'] ?? 0.0,
                'rating': userData['rating'] ?? 0.0,
                'walletBalance': userData['walletBalance'] ?? 0.0,
              }
            : null,
        bookings: bookings,
        offeredRides: offeredRides,
        reviews: reviews,
        payments: payments,
        alerts: alerts,
        reports: reports,
        notifications: notifications,
        sosAlerts: sosAlerts,
        globalRides: globalRides,
        safetySettings: safetySettings,
      );

      // ✅ Add conversation to history
      _conversationHistory.add({'role': 'user', 'content': text});
      _conversationHistory.add({'role': 'assistant', 'content': aiText});


      // ✅ Keep history manageable (last 20 messages)
      if (_conversationHistory.length > 20) {
        _conversationHistory.removeAt(0);
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'text': aiText,
            'isUser': false,
            'isError': false,
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      if (mounted) {
        // ✅ Remove last user message from history on error
        if (_conversationHistory.isNotEmpty) {
          _conversationHistory.removeLast();
        }
        setState(() {
          _messages.add({
            'text': _getErrorMessage(e.toString()),
            'isUser': false,
            'isError': true,
          });
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  String _getErrorMessage(String error) {
    debugPrint('Error details: $error');
    if (error.contains('timeout')) {
      return '⏱️ Request timed out!\nPlease check your internet and try again.';
    }
    if (error.contains('Mistral') || error.contains('401') || error.contains('403')) {
      return '🔑 Mistral API Key issue!\nPlease check the console configuration.';
    }
    if (error.contains('Tavily')) {
      return '🌐 Tavily Search error!\nI cannot get real-time info right now.';
    }
    if (error.contains('quota') ||
        error.contains('QUOTA') ||
        error.contains('429') ||
        error.contains('Resource has been exhausted')) {
      return '📊 Daily limit reached!\nFree tier allows limited requests.\nPlease try again after some time!';
    }
    if (error.contains('network') ||
        error.contains('Socket') ||
        error.contains('connection') ||
        error.contains('SocketException')) {
      return '🌐 No internet connection!\nPlease check your network and try again.';
    }
    if (error.contains('empty_response')) {
      return '🤔 I didn\'t get a response.\nPlease try asking again!';
    }
    if (error.contains('SAFETY')) {
      return '⚠️ I cannot respond to that question.\nPlease ask something related to carpooling!';
    }
    return '❌ Something went wrong!\nPlease try again.\n\nDetails: $error';
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
      _addWelcomeMessage();
    });
  }

  final List<Map<String, dynamic>> _suggestions = [
    {'text': '🗺️ Best route Noida → Gurgaon?'},
    {'text': '💰 Split ₹300 for 3 people?'},
    {'text': '🚦 Best time to travel Delhi → Agra?'},
    {'text': '🛡️ Safety tips for women riders?'},
    {'text': '⏱️ How early to book a ride?'},
    {'text': '🤝 Carpooling etiquette tips?'},
  ];

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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            SizedBox(width: 16.w),
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded,
                  color: AppColors.white, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SaathChalo AI',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Powered by Mistral & Tavily',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New Chat',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Suggestions — show only at start
          if (_messages.length <= 2) _buildSuggestions(),

          _buildInputBox(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'];
    final bool isError = message['isError'] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.smart_toy_rounded,
                color: isError ? AppColors.error : AppColors.primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 8.w),
          ],

          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : isError
                    ? AppColors.error.withValues(alpha: 0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
                border: isError
                    ? Border.all(
                    color: AppColors.error.withValues(alpha: 0.3))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message['text'],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isUser
                      ? AppColors.white
                      : isError
                      ? AppColors.error
                      : AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),

          if (isUser) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_rounded,
                color: AppColors.primary, size: 18.sp),
          ),
          SizedBox(width: 8.w),
          Container(
            padding:
            EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  3, (i) => _AnimatedDot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return GestureDetector(
            onTap: () {
              _messageController.text = s['text']!;
              _sendMessage();
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                s['text']!,
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
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
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
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
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46.w,
                height: 46.w,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? AppColors.border
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.send_rounded,
                  color: AppColors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Animated typing dots
class _AnimatedDot extends StatefulWidget {
  final int delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          width: 8.w,
          height: 8.w + (_anim.value * 4),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          decoration: BoxDecoration(
            color: AppColors.primary
                .withValues(alpha: 0.3 + (_anim.value * 0.7)),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      },
    );
  }
}