import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant/chat_message.dart';

void main() {
  group('ChatMessage', () {
    test('round-trips through JSON', () {
      const message = ChatMessage(role: ChatRole.user, text: 'Hello there');

      final restored = ChatMessage.fromJson(message.toJson());

      expect(restored.role, ChatRole.user);
      expect(restored.text, 'Hello there');
    });

    test('defaults an unrecognized role to assistant', () {
      final restored = ChatMessage.fromJson({'role': 'model', 'text': 'Hi'});

      expect(restored.role, ChatRole.assistant);
    });
  });
}
