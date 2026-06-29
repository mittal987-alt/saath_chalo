import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/secrets.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  // ⚠️ Replace with your Gemini API Key
  static const String _apiKey = Secrets.geminiApiKey;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // System prompt for SaathChalo AI
  static const String _systemPrompt = '''
You are SaathChalo AI Assistant, a helpful travel companion for an Indian carpooling app called SaathChalo.

Your role is to:
1. Help users find best carpooling routes in India
2. Give travel tips and safety advice
3. Help calculate fare splits between passengers
4. Suggest best travel times to avoid traffic
5. Answer questions about carpooling etiquette
6. Give advice about popular routes in Indian cities
7. Help with ride safety tips especially for women
8. Answer in both Hindi and English based on user preference

Key information about SaathChalo app:
- It connects drivers and riders going on same routes
- Users can offer or find rides
- Payment is done via UPI/Razorpay
- Live location sharing available
- SOS emergency feature available
- Women only ride option available

Always be friendly, helpful and concise. Use emojis to make responses engaging.
For fare calculation: typical carpooling fare is ₹2-4 per km per seat.
''';

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _addWelcomeMessage();
  }

  void _initializeAI() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = _model.startChat();
  }

  void _addWelcomeMessage() {
    _messages.add({
      'text': '🙏 Namaste! I am SaathChalo AI Assistant!\n\nI can help you with:\n\n🗺️ Find best routes\n💰 Calculate fare splits\n🚦 Best travel times\n🛡️ Safety tips\n💬 Carpooling advice\n\nHow can I help you today?',
      'isUser': false,
      'isError': false,
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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
      final response = await _chat.sendMessage(Content.text(text));
      final responseText = response.text ?? 'Sorry, I could not understand that!';

      setState(() {
        _messages.add({
          'text': responseText,
          'isUser': false,
          'isError': false,
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text': '❌ Sorry, I am having trouble connecting. Please check your internet and try again!',
          'isUser': false,
          'isError': true,
        });
        _isLoading = false;
      });
    }

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

  // Quick suggestion questions
  final List<String> _suggestions = [
    '🗺️ Best route from Noida to Gurgaon?',
    '💰 How to split fare for 3 people?',
    '🚦 Best time to travel Delhi to Agra?',
    '🛡️ Safety tips for women riders?',
    '⏱️ How early should I book a ride?',
    '🤝 Carpooling etiquette tips?',
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
        title: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
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
                      'Powered by Gemini AI',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.white.withOpacity(0.8),
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
            onPressed: () {
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
              _initializeAI(); // ← Fixed line outside setState
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'New Chat',
          ),
        ],

      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Suggestions
          if (_messages.length <= 2)
            _buildSuggestions(),

          // Input
          _buildInput(),
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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 18.sp),
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
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
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

          if (isUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(Icons.person_rounded,
                  color: AppColors.primary, size: 16.sp),
            ),
          ],
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
              color: AppColors.primary.withOpacity(0.1),
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
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4.w),
                _buildDot(1),
                SizedBox(width: 4.w),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppColors.primary
                .withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 40.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _messageController.text = _suggestions[index];
              _sendMessage();
            },
            child: Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(
                  horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                _suggestions[index],
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

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 8.h),
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
              child: Container(
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