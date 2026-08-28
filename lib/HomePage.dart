import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/FeatureBox.dart';
import 'package:voice_assistant/chat_message.dart';
import 'package:voice_assistant/gemini_service.dart';
import 'package:voice_assistant/pallete.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();
  String lastWords = '';
  final GeminiService geminiService = GeminiService();

  //timings for animations of feature boxes
  int start = 200;
  int delay = 200;

  final List<ChatMessage> chatHistory = [];
  bool isProcessing = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  //plugin for text to speech
  Future<void> initTextToSpeech() async {
    //for ios only
    await flutterTts.setSharedInstance(true);
    setState(() {});
  }

  //adding plugin in function for speech to text convertor
  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  //when user clicks on mic,it is called
  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
    setState(() {});
  }

  //when user stops
  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  //it runs when it regonize some words and save it in last words
  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  //for system speaking from text
  Future<void> systemSpeaks(String content) async {
    await flutterTts.speak(content);
  }

  //when leaves screen it is called to prevent resource leak
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auraly'),
        leading: Icon(Icons.menu),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //picture
            ZoomIn(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Pallete.assistantCircleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    height: 123,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/images/virtualAssistant.png'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //chat history, or the greeting bubble if nothing has been said yet
            if (chatHistory.isEmpty && !isProcessing)
              FadeInRight(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin: EdgeInsets.symmetric(
                    horizontal: 40,
                  ).copyWith(top: 30),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: Pallete.whiteColor,
                    borderRadius: BorderRadius.circular(
                      20,
                    ).copyWith(topLeft: Radius.zero),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "Good Morning,what task can I do for you?",
                      style: TextStyle(
                        color: Pallete.mainFontColor,
                        fontSize: 20,
                        fontFamily: 'Cera Pro',
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ).copyWith(top: 20),
                child: Column(
                  children: [
                    for (final message in chatHistory)
                      _ChatBubble(message: message),
                    if (isProcessing) const _ThinkingBubble(),
                  ],
                ),
              ),
            Visibility(
              //when gemini shows data don't show these boxes
              visible: chatHistory.isEmpty,
              child: Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(left: 20, top: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Here are a few features',
                  style: TextStyle(
                    fontFamily: 'Cera Pro',
                    fontSize: 20,
                    color: Pallete.mainFontColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Visibility(
              //when gemini shows data don't show these boxes
              visible: chatHistory.isEmpty,
              child: Column(
                children: [
                  //feature boxes
                  SlideInLeft(
                    delay: Duration(milliseconds: start),
                    child: Featurebox(
                      color: Pallete.firstSuggestionBoxColor,
                      headerText: 'Gemini AI',
                      descText:
                          'A smarter way to stay organized and informed, powered by Google Gemini',
                    ),
                  ),
                  SizedBox(height: 10),
                  SlideInLeft(
                    delay: Duration(milliseconds: start + delay),
                    child: Featurebox(
                      color: Pallete.thirdSuggestionBoxColor,
                      headerText: 'Smart Voice Assistant',
                      descText:
                          'Speak naturally and get spoken answers back, powered by Gemini',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ZoomIn(
        delay: Duration(milliseconds: start + 3 * delay),
        child: FloatingActionButton(
          backgroundColor: Pallete.firstSuggestionBoxColor,
          onPressed: () async {
            //ignore taps while a request is already in flight
            if (isProcessing) return;

            if (speechToText.isListening) {
              await stopListening();
              final userMessage = lastWords;
              if (userMessage.trim().isEmpty) return;
              setState(() {
                chatHistory.add(
                  ChatMessage(role: ChatRole.user, text: userMessage),
                );
                isProcessing = true;
              });
              try {
                final speech = await geminiService.getResponse(userMessage);
                setState(() {
                  chatHistory.add(
                    ChatMessage(role: ChatRole.assistant, text: speech),
                  );
                });
                await systemSpeaks(speech);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } finally {
                setState(() => isProcessing = false);
              }
            } else {
              await startListening();
            }
          },
          child: isProcessing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Pallete.mainFontColor,
                  ),
                )
              : Icon(speechToText.isListening ? Icons.stop : Icons.mic),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Pallete.firstSuggestionBoxColor : Pallete.whiteColor,
          border: isUser ? null : Border.all(color: Pallete.borderColor),
          borderRadius: BorderRadius.circular(18).copyWith(
            topLeft: isUser ? null : Radius.zero,
            topRight: isUser ? Radius.zero : null,
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: Pallete.mainFontColor,
            fontSize: 16,
            fontFamily: 'Cera Pro',
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Pallete.whiteColor,
          border: Border.all(color: Pallete.borderColor),
          borderRadius: BorderRadius.circular(18).copyWith(topLeft: Radius.zero),
        ),
        child: SizedBox(
          width: 20,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Pallete.mainFontColor,
          ),
        ),
      ),
    );
  }
}
