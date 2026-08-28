import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:voice_assistant/api_key_store.dart';
import 'package:voice_assistant/chat_message.dart';

//status codes worth retrying: rate limited or the model is momentarily overloaded
const _retryableStatusCodes = {429, 503};

class GeminiService {
  //stores conversation history in Gemini's "contents" format
  final List<Map<String, dynamic>> messages = [];

  //builds and sends a fresh request each attempt, retrying with backoff on
  //network failures or transient (429/503) server errors, so a flaky
  //connection or a brief model overload doesn't surface as a hard error
  Future<http.StreamedResponse> _sendWithRetry(
    http.Request Function() buildRequest, {
    int maxAttempts = 3,
  }) async {
    for (var attempt = 1; ; attempt++) {
      final isLastAttempt = attempt >= maxAttempts;
      try {
        final response = await http.Client().send(buildRequest());
        if (isLastAttempt || !_retryableStatusCodes.contains(response.statusCode)) {
          return response;
        }
      } on SocketException {
        if (isLastAttempt) {
          throw Exception(
            'No internet connection. Please check your network and try again.',
          );
        }
      } on http.ClientException {
        if (isLastAttempt) rethrow;
      }
      await Future.delayed(Duration(seconds: attempt));
    }
  }

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
  String _errorMessageFromBody(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      final message = decoded['error']?['message'];
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {}
    return 'Request failed with status $statusCode';
  }

  //streams the response text as it's generated, yielding the accumulated
  //text so far on each chunk
  Stream<String> getResponseStream(String prompt) async* {
    messages.add({
      'role': 'user',
      'parts': [
        {'text': prompt},
      ],
    });
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No Gemini API key found. Please sign in again.');
    }
    final streamedResponse = await _sendWithRetry(() {
      final request = http.Request(
        'POST',
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:streamGenerateContent?alt=sse&key=$apiKey',
        ),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'contents': messages});
      return request;
    });
    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw Exception(_errorMessageFromBody(body, streamedResponse.statusCode));
    }

    final buffer = StringBuffer();
    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final jsonStr = line.substring(6).trim();
      if (jsonStr.isEmpty) continue;
      final decoded = jsonDecode(jsonStr);
      final text =
          decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text is String) {
        buffer.write(text);
        yield buffer.toString();
      }
    }

    messages.add({
      'role': 'model',
      'parts': [
        {'text': buffer.toString()},
      ],
    });
  }

}
