import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/chat_message.dart';
import 'package:voice_assistant/conversation.dart';

class ConversationStore {
  static const _conversationsKey = 'conversations';
  static const _legacyHistoryKey = 'chat_history';

  //loads all saved conversations, newest first. Transparently migrates the
  //single-conversation history from older versions of the app, if present.
  Future<List<Conversation>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_conversationsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final conversations = decoded
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList();
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return conversations;
    }

    final legacyRaw = prefs.getString(_legacyHistoryKey);
    if (legacyRaw == null) return [];
    final legacyMessages = (jsonDecode(legacyRaw) as List<dynamic>)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
    await prefs.remove(_legacyHistoryKey);
    if (legacyMessages.isEmpty) return [];
    final firstUserMessage = legacyMessages
        .firstWhere(
          (m) => m.role == ChatRole.user,
          orElse: () => legacyMessages.first,
        )
        .text;
    final migrated = Conversation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: Conversation.titleFrom(firstUserMessage),
      messages: legacyMessages,
      updatedAt: DateTime.now(),
    );
    await saveAll([migrated]);
    return [migrated];
  }

  Future<void> saveAll(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_conversationsKey, encoded);
  }
}
