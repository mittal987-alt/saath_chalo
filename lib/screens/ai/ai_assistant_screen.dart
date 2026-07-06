import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
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
  final List<Map<String, dynamic>> _conversationHistory = [];
  bool _isLoading = false;

  static const String _systemPrompt = '''
You are SaathChalo AI, a helpful carpooling assistant for India.
Help users with:
- Finding best carpool routes in Indian cities
- Calculating fare splits
- Safety tips especially for women
- Best travel times to avoid traffic
- Carpooling etiquette
- How to use the SaathChalo app
- General travel advice in India

Keep responses concise, friendly and helpful.
Use emojis to make responses engaging.
When asked about routes, suggest realistic Indian city routes.
For fare calculation: typical rate is Rs 2-4 per km per person.
Always respond in the same language the user writes in (Hindi or English).
''';

  // ✅ Supports both AIzaSy and AQ. key formats
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

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
      // ✅ Add to conversation history for context
      _conversationHistory.add({
        'role': 'user',
        'parts': [
          {'text': text}
        ],
      });

      final url = Uri.parse('$_baseUrl?key=${Secrets.geminiApiKey}');

      final requestBody = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': _systemPrompt}
          ]
        },
        'contents': _conversationHistory,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
          'topP': 0.8,
          'topK': 40,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_ONLY_HIGH'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_ONLY_HIGH'
          },
        ],
      });

      debugPrint('Sending to Gemini API...');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('timeout'),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Safe extraction of response text
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('empty_response');
        }

        final content = candidates[0]['content'];
        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('empty_response');
        }

        final aiText = parts[0]['text']?.toString() ?? '';
        if (aiText.isEmpty) throw Exception('empty_response');

        // ✅ Add AI response to history
        _conversationHistory.add({
          'role': 'model',
          'parts': [
            {'text': aiText}
          ],
        });

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
      } else {
        debugPrint('Error body: ${response.body}');
        final error = jsonDecode(response.body);
        final msg =
            error['error']?['message'] ?? 'Status ${response.statusCode}';
        throw Exception(msg);
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
    if (error.contains('API_KEY') ||
        error.contains('apiKey') ||
        error.contains('API key') ||
        error.contains('400')) {
      return '🔑 API Key issue!\nPlease check your Gemini API key.\n\nGet a new key from:\naistudio.google.com/app/apikey';
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
                      'Powered by Gemini 2.0',
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
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
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
                    ? AppColors.error.withOpacity(0.08)
                    : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
                border: isError
                    ? Border.all(
                    color: AppColors.error.withOpacity(0.3))
                    : null,
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
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.25)),
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
                .withOpacity(0.3 + (_anim.value * 0.7)),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      },
    );
  }
}