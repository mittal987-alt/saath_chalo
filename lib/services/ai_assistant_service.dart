import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants/secrets.dart';

class AIAssistantService {
  static const String mistralApiUrl =
      'https://api.mistral.ai/v1/chat/completions';

  static const String tavilyApiUrl =
      'https://api.tavily.com/search';

  static const String sarvamApiUrl =
      'https://api.sarvam.ai/inscribe/v1/chat/completions';

  /// Main entry point for the AI Assistant.
  /// It uses Mistral as the primary LLM and Tavily for real-time web search.
  static Future<String> askAssistant({
    required String message,
    List<Map<String, dynamic>> history = const [],
    Map<String, dynamic>? user,
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? offeredRides,
    List<Map<String, dynamic>>? reviews,
    List<Map<String, dynamic>>? payments,
    List<Map<String, dynamic>>? alerts,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? sosAlerts,
    List<Map<String, dynamic>>? globalRides,
    Map<String, dynamic>? safetySettings,
  }) async {
    // 1. Build local context from Firestore data
    final contextSummary = buildContextSummary(
      user: user,
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

    // 2. Decide if we need web search (real-time info)
    String webContext = '';
    if (_shouldSearchWeb(message)) {
      webContext = await searchWeb(message);
    }

    // 3. Construct the Master System Prompt
    final systemPrompt = '''
You are SaathChalo AI, the intelligent assistant for the SaathChalo carpooling platform in India.
Your goal is to provide accurate, helpful, and data-driven assistance to users regarding their travels, costs, and safety.

--- APP CONTEXT (User Data & Platform Status) ---
$contextSummary

--- REAL-TIME WEB CONTEXT (via Tavily) ---
${webContext.isEmpty ? 'No real-time web data available for this query.' : webContext}

--- INSTRUCTIONS ---
- ALWAYS answer in the same language as the user (Hindi, English, etc.).
- Be concise, professional, and friendly.
- Use the APP CONTEXT for any questions about the user's specific rides, wallet balance, payments, reports, safety settings, or history.
- If the user asks about available rides, check the "Global Rides" section in the APP CONTEXT.
- Use the WEB CONTEXT for real-time information like traffic, weather, or location-specific details.
- If data is missing from both contexts, politely inform the user instead of hallucinating.
- Focus on carpooling, safety, and cost-efficiency.
- Maintain a helpful tone.
''';

    // 4. Prepare messages for Mistral
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add conversation history
    for (var chat in history) {
      messages.add({
        'role': chat['role'] == 'user' ? 'user' : 'assistant',
        'content': chat['content'] ?? '',
      });
    }

    // Add current message
    messages.add({'role': 'user', 'content': message});

    // 5. Call Mistral (Primary)
    if (Secrets.mistralApiKey.isNotEmpty && Secrets.mistralApiKey != 'YOUR_MISTRAL_API_KEY_HERE') {
      try {
        return await _askMistral(messages);
      } catch (e) {
        debugPrint('Mistral failed: $e');
      }
    }

    // Fallback to Sarvam if Mistral fails or is missing (Sarvam is good for Indian languages)
    if (Secrets.sarvamApiKey.isNotEmpty && Secrets.sarvamApiKey != 'YOUR_SARVAM_API_KEY_HERE') {
      return _askSarvam(message);
    }

    return _fallbackReply(message, contextSummary);
  }

  /// Determines if the query requires external real-time data.
  static bool _shouldSearchWeb(String message) {
    final query = message.toLowerCase();
    final webKeywords = [
      'traffic', 'weather', 'road condition', 'route from', 'how is the way',
      'news', 'current', 'today', 'latest', 'advisory', 'distance between',
      'place', 'location', 'where is', 'mausam', 'rasta', 'bhidi', 'jaam', 'pani', 'baarish', 'traffic update'
    ];
    return webKeywords.any((k) => query.contains(k));
  }

  static Future<String> _askMistral(List<Map<String, dynamic>> messages) async {
    final response = await http.post(
      Uri.parse(mistralApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Secrets.mistralApiKey}',
      },
      body: jsonEncode({
        'model': 'mistral-small-latest',
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Mistral request failed: ${response.body}');
    }

    final body = jsonDecode(response.body);
    final choices = body['choices'] as List<dynamic>?;
    final responseMessage = choices?.firstOrNull?['message'] as Map<String, dynamic>?;
    final content = responseMessage?['content']?.toString();
    return content?.trim() ?? 'I encountered an issue processing your request.';
  }

  static Future<String> _askSarvam(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(sarvamApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': Secrets.sarvamApiKey,
        },
        body: jsonEncode({
          'model': 'sarvam-chat-v1',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sarvam request failed: ${response.body}');
      }

      final body = jsonDecode(response.body);
      final choices = body['choices'] as List<dynamic>?;
      final message = choices?.firstOrNull?['message'] as Map<String, dynamic>?;
      final content = message?['content']?.toString();
      return content?.trim() ?? 'I could not generate a response.';
    } catch (e) {
      throw Exception('Sarvam Error: $e');
    }
  }

  static Future<String> searchWeb(String query) async {
    if (Secrets.tavilyApiKey.isEmpty || Secrets.tavilyApiKey == 'YOUR_TAVILY_API_KEY_HERE') {
      return '';
    }

    try {
      final response = await http.post(
        Uri.parse(tavilyApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': Secrets.tavilyApiKey,
          'query': query,
          'search_depth': 'basic',
          'max_results': 3,
        }),
      );

      if (response.statusCode != 200) return '';

      final body = jsonDecode(response.body);
      final results = body['results'] as List<dynamic>?;
      final snippets = <String>[];
      for (final item in results ?? const []) {
        final title = item['title']?.toString() ?? '';
        final snippet = item['content']?.toString() ?? '';
        if (title.isNotEmpty || snippet.isNotEmpty) {
          snippets.add('[$title]: $snippet');
        }
      }
      return snippets.join('\n\n');
    } catch (e) {
      return '';
    }
  }

  static String buildContextSummary({
    Map<String, dynamic>? user,
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? offeredRides,
    List<Map<String, dynamic>>? reviews,
    List<Map<String, dynamic>>? payments,
    List<Map<String, dynamic>>? alerts,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? sosAlerts,
    List<Map<String, dynamic>>? globalRides,
    Map<String, dynamic>? safetySettings,
  }) {
    final name = user?['name']?.toString() ?? 'User';
    final totalRides = user?['totalRides'] ?? 0;
    final moneySaved = user?['totalMoneySaved'] ?? 0.0;
    final co2Saved = user?['totalCo2Saved'] ?? 0.0;
    final rating = user?['rating'] ?? 0.0;
    final walletBalance = user?['walletBalance'] ?? 0.0;

    final rideSummary = (bookings ?? []).map((ride) => 
      '- ${ride['from']} to ${ride['to']} | Status: ${ride['status']} | Fare: ₹${ride['totalPrice']}'
    ).join('\n');

    final offeredSummary = (offeredRides ?? []).map((ride) => 
      '- ${ride['from']} to ${ride['to']} | Seats: ${ride['availableSeats']} | Price: ₹${ride['pricePerSeat']}'
    ).join('\n');

    final reviewSummary = (reviews ?? []).map((rev) => 
      '- Rating: ${rev['rating']} | ${rev['comment']}'
    ).join('\n');

    final paymentSummary = (payments ?? []).map((pay) => 
      '- ₹${pay['amount']} | Status: ${pay['status']} | Method: ${pay['method']}'
    ).join('\n');

    final alertSummary = (alerts ?? []).map((alt) => 
      '- Route: ${alt['from']} to ${alt['to']} | Active: ${alt['isActive']}'
    ).join('\n');

    final reportSummary = (reports ?? []).map((rep) => 
      '- Type: ${rep['type']} | Status: ${rep['status']} | Reason: ${rep['reason']}'
    ).join('\n');

    final notifSummary = (notifications ?? []).map((n) => 
      '- ${n['title']}: ${n['body']}'
    ).take(5).join('\n');

    final sosSummary = (sosAlerts ?? []).map((s) => 
      '- SOS Incident: ${s['status']} at ${s['timestamp']}'
    ).join('\n');

    final globalSummary = (globalRides ?? []).map((r) => 
      '- Available: ${r['from']} to ${r['to']} (₹${r['pricePerSeat']}/seat)'
    ).take(10).join('\n');

    final safetyInfo = safetySettings != null ? '''
- SOS Enabled: ${safetySettings['sosEnabled'] ?? true}
- Emergency Contacts: ${(safetySettings['emergencyContacts'] as List?)?.length ?? 0} configured
''' : '- No custom safety settings.';

    return '''
User Profile:
- Name: $name
- Rides Completed: $totalRides
- Money Saved: ₹$moneySaved
- CO2 Saved: $co2Saved kg
- Wallet Balance: ₹$walletBalance
- Avg Rating: $rating

Safety Config:
$safetyInfo

Recent Activity:
- Recent Bookings: ${rideSummary.isEmpty ? 'None' : rideSummary}
- Your Offers: ${offeredSummary.isEmpty ? 'None' : offeredSummary}
- Recent Payments: ${paymentSummary.isEmpty ? 'None' : paymentSummary}
- SOS History: ${sosSummary.isEmpty ? 'None' : sosSummary}
- Notifications: ${notifSummary.isEmpty ? 'None' : notifSummary}

Platform Alerts & Rides:
- Ride Alerts: ${alertSummary.isEmpty ? 'None' : alertSummary}
- Global Active Rides: ${globalSummary.isEmpty ? 'No rides available currently.' : globalSummary}

Recent Reviews:
${reviewSummary.isEmpty ? 'No reviews yet.' : reviewSummary}
''';
  }

  static String _fallbackReply(String message, String contextSummary) {
    return 'I am currently operating in basic mode. Based on your profile, you have saved ₹${contextSummary.contains('Money Saved: ₹') ? contextSummary.split('Money Saved: ₹')[1].split('\n')[0] : '0'} and completed ${contextSummary.contains('Rides Completed: ') ? contextSummary.split('Rides Completed: ')[1].split('\n')[0] : '0'} rides. How else can I assist?';
  }
}

extension _ListExt on List<dynamic> {
  dynamic get firstOrNull => isEmpty ? null : first;
}
