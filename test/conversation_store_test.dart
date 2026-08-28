import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/chat_message.dart';
import 'package:voice_assistant/conversation.dart';
import 'package:voice_assistant/conversation_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadAll returns an empty list when nothing was saved', () async {
    final store = ConversationStore();

    expect(await store.loadAll(), isEmpty);
  });

  test('saveAll then loadAll returns conversations newest first', () async {
    final store = ConversationStore();
    final older = Conversation(
      id: '1',
      title: 'Older chat',
      messages: [const ChatMessage(role: ChatRole.user, text: 'Hi')],
      updatedAt: DateTime(2024, 1, 1),
    );
    final newer = Conversation(
      id: '2',
      title: 'Newer chat',
      messages: [const ChatMessage(role: ChatRole.user, text: 'Hello')],
      updatedAt: DateTime(2024, 6, 1),
    );

    await store.saveAll([older, newer]);
    final loaded = await store.loadAll();

    expect(loaded.map((c) => c.id).toList(), ['2', '1']);
  });

  test('migrates a legacy single chat_history into one conversation', () async {
    SharedPreferences.setMockInitialValues({
      'chat_history': '[{"role":"user","text":"What is Flutter?"}]',
    });
    final store = ConversationStore();

    final loaded = await store.loadAll();

    expect(loaded.length, 1);
    expect(loaded.first.title, 'What is Flutter?');
    expect(loaded.first.messages.single.text, 'What is Flutter?');
  });
}
