import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:voice_assistant/secrets.dart';

class OpenAIService {
  //creates a list for storing chatgpt response
  final List<Map<String, String>> messages = [];

  //main API CALL
  Future<String> isArtAPI(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content - Type': "application/json",
          'Authorization': "Bearer $openAIAPIKey",
        },
        body: jsonEncode({
          "model": "gpt-5",
          "messages": [
            {
              'role': 'user',
              'content':
                  'Does this message want to generate an image,art or anything similar? $prompt . simply answer it with yes or no.',
            },
          ],
        }),
      );
      print(res.body);
      if (res.statusCode == 200) {
        String content = jsonDecode(
          res.body,
        )['choices'][0]['message']['content'];
        //removes spaces
        content = content.trim();
        switch (content) {
          case 'Yes':
          case 'yes':
          case 'Yes.':
          case 'yes.':
            //if says yes then call dallapi otherwise chatgpt
            final res = await dallEAPI(prompt);
            return res;
          default:
            final res = await chatGPTAPI(prompt);
            return res;
        }
      }
      return 'An internal error occured';
    } catch (e) {
      return e.toString();
    }
  }

  //chatgpt api
  Future<String> chatGPTAPI(String prompt) async {
    //storing user data whatever he speaks
    messages.add({'role': 'user', 'content': prompt});
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content - Type': "application/json",
          'Authorization': "Bearer $openAIAPIKey",
        },
        body: jsonEncode({"model": "gpt-5", "messages": messages}),
      );
      print(res.body);
      if (res.statusCode == 200) {
        String content = jsonDecode(
          res.body,
        )['choices'][0]['message']['content'];
        //removes spaces
        content = content.trim();
        //here user is assitant it means chatgpt is responding
        messages.add({'role': 'assistant', 'content': content});
        return content;
      }
      return 'An internal error occured';
    } catch (e) {
      return e.toString();
    }
  }

  //dallE api
  Future<String> dallEAPI(String prompt) async {
    //if user asks questions regrading art so here we go
    messages.add({'role': 'user', 'content': prompt});
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content - Type': "application/json",
          'Authorization': "Bearer $openAIAPIKey",
        },
        body: jsonEncode({'model': "gpt-image-1", 'prompt': prompt, 'n': 1}),
      );
      print(res.body);
      if (res.statusCode == 200) {
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        //removes spaces
        imageUrl = imageUrl.trim();
        //here user is assitant it means chatgpt is responding
        messages.add({'role': 'assistant', 'content': imageUrl});
        return imageUrl;
      }
      return 'An internal error occured';
    } catch (e) {
      return e.toString();
    }
  }
}
