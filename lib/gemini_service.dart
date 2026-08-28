import 'package:firebase_ai/firebase_ai.dart';
import 'package:voice_assistant/chat_message.dart';

class GeminiService {
  final _model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.6-flash',
  );

  //stores conversation history in Firebase AI's Content format
  final List<Content> messages = [];

  //rebuilds Gemini's conversation context from previously saved chat history,
  //so a restored session still remembers what was said
  void restoreHistory(List<ChatMessage> history) {
    messages
      ..clear()
      ..addAll(
        history.map(
          (message) => message.role == ChatRole.user
              ? Content.text(message.text)
              : Content.model([TextPart(message.text)]),
        ),
      );
  }

  //streams the response text as it's generated, yielding the accumulated
  //text so far on each chunk
  Stream<String> getResponseStream(String prompt) async* {
    messages.add(Content.text(prompt));
    final buffer = StringBuffer();
    try {
      await for (final chunk in _model.generateContentStream(messages)) {
        final text = chunk.text;
        if (text != null) {
          buffer.write(text);
          yield buffer.toString();
        }
      }
    } on FirebaseAIException catch (e) {
      throw Exception(e.message);
    }

    messages.add(Content.model([TextPart(buffer.toString())]));
  }
}
