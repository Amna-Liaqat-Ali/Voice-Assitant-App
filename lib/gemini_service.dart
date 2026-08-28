import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:voice_assistant/chat_message.dart';
import 'package:voice_assistant/secrets.dart';
import 'package:voice_assistant/settings_page.dart';

class GeminiService {
  //stores conversation history in Gemini's "contents" format
  final List<Map<String, dynamic>> messages = [];

  //rebuilds Gemini's conversation context from previously saved chat history,
  //so a restored session still remembers what was said
  void restoreHistory(List<ChatMessage> history) {
    messages.clear();
    for (final message in history) {
      messages.add({
        'role': message.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      });
    }
  }

  //extracts a readable message from a Gemini error response body
  String _errorMessageFrom(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      final message = decoded['error']?['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return 'Request failed with status ${res.statusCode}';
  }

  Future<String> getResponse(String prompt) async {
    messages.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });
    final apiKey = await loadApiKeyOverride() ?? geminiAPIKey;
    final res = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$apiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': messages}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessageFrom(res));
    }
    String content =
        jsonDecode(res.body)['candidates'][0]['content']['parts'][0]['text'];
    content = content.trim();
    messages.add({
      'role': 'model',
      'parts': [
        {'text': content},
      ],
    });
    return content;
  }
}
