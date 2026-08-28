import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/chat_history_store.dart';
import 'package:voice_assistant/chat_message.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns an empty list when nothing was saved', () async {
    final store = ChatHistoryStore();

    expect(await store.load(), isEmpty);
  });

  test('save then load returns an equivalent history', () async {
    final store = ChatHistoryStore();
    final history = [
      const ChatMessage(role: ChatRole.user, text: 'What is Flutter?'),
      const ChatMessage(role: ChatRole.assistant, text: 'A UI toolkit.'),
    ];

    await store.save(history);
    final loaded = await store.load();

    expect(loaded.length, 2);
    expect(loaded[0].role, ChatRole.user);
    expect(loaded[0].text, 'What is Flutter?');
    expect(loaded[1].role, ChatRole.assistant);
    expect(loaded[1].text, 'A UI toolkit.');
  });

  test('clear removes the saved history', () async {
    final store = ChatHistoryStore();
    await store.save([
      const ChatMessage(role: ChatRole.user, text: 'Hi'),
    ]);

    await store.clear();

    expect(await store.load(), isEmpty);
  });
}
