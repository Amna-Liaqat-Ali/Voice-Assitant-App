import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/chat_message.dart';

class ChatHistoryStore {
  static const _key = 'chat_history';

  Future<List<ChatMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<ChatMessage> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((m) => m.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
