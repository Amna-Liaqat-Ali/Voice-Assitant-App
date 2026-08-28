import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/FeatureBox.dart';
import 'package:voice_assistant/chat_history_store.dart';
import 'package:voice_assistant/chat_message.dart';
import 'package:voice_assistant/gemini_service.dart';
import 'package:voice_assistant/pallete.dart';
import 'package:voice_assistant/settings_page.dart';

class Homepage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const Homepage({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

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
  final chatHistoryStore = ChatHistoryStore();
  final textController = TextEditingController();
  final scrollController = ScrollController();
  bool isProcessing = false;
  bool isSpeaking = false;

  //keeps the latest message in view as the conversation grows or streams in
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
    loadChatHistory();
  }

  //restores a previous conversation from disk, if any
  Future<void> loadChatHistory() async {
    final saved = await chatHistoryStore.load();
    if (saved.isEmpty) return;
    geminiService.restoreHistory(saved);
    setState(() => chatHistory.addAll(saved));
    _scrollToBottom();
  }

  //wipes the current conversation, both on screen and on disk
  Future<void> clearChatHistory() async {
    await chatHistoryStore.clear();
    geminiService.restoreHistory([]);
    setState(() => chatHistory.clear());
  }

  //plugin for text to speech
  Future<void> initTextToSpeech() async {
    //for ios only
    await flutterTts.setSharedInstance(true);
    flutterTts.setStartHandler(() => setState(() => isSpeaking = true));
    flutterTts.setCompletionHandler(() => setState(() => isSpeaking = false));
    flutterTts.setCancelHandler(() => setState(() => isSpeaking = false));
    flutterTts.setErrorHandler((_) => setState(() => isSpeaking = false));
    setState(() {});
  }

  //lets the user cut off the assistant mid-sentence
  Future<void> stopSpeaking() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  //adding plugin in function for speech to text convertor
  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  //when user clicks on mic,it is called
  Future<void> startListening() async {
    final locale = await loadAssistantLocale();
    await speechToText.listen(
      onResult: onSpeechResult,
      localeId: locale,
    );
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
    await flutterTts.setLanguage(await loadAssistantLocale());
    await flutterTts.setSpeechRate(await loadSpeechRate());
    await flutterTts.setPitch(await loadSpeechPitch());
    await flutterTts.speak(content);
  }

  //when leaves screen it is called to prevent resource leak
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
    textController.dispose();
    scrollController.dispose();
  }

  //shared by both the mic flow and the typed-message flow
  Future<void> sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || isProcessing) return;
    setState(() {
      chatHistory.add(ChatMessage(role: ChatRole.user, text: userMessage));
      chatHistory.add(const ChatMessage(role: ChatRole.assistant, text: ''));
      isProcessing = true;
    });
    _scrollToBottom();
    try {
      String speech = '';
      await for (final partial in geminiService.getResponseStream(
        userMessage,
      )) {
        speech = partial;
        setState(() {
          chatHistory[chatHistory.length - 1] = ChatMessage(
            role: ChatRole.assistant,
            text: speech,
          );
        });
        _scrollToBottom();
      }
      await chatHistoryStore.save(chatHistory);
      await systemSpeaks(speech);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  //puts a previously sent message back into the input box for editing,
  //dropping it and everything after it from the conversation
  Future<void> editMessage(ChatMessage message) async {
    final index = chatHistory.indexOf(message);
    if (index == -1) return;
    setState(() => chatHistory.removeRange(index, chatHistory.length));
    geminiService.restoreHistory(chatHistory);
    await chatHistoryStore.save(chatHistory);
    textController.text = message.text;
    textController.selection = TextSelection.collapsed(
      offset: textController.text.length,
    );
  }

  void _sendTypedMessage() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    textController.clear();
    sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auraly'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettingsPage(
                themeMode: widget.themeMode,
                onToggleTheme: widget.onToggleTheme,
                onClearChat: clearChatHistory,
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isSpeaking)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined),
              tooltip: 'Stop speaking',
              onPressed: stopSpeaking,
            ),
          if (chatHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: clearChatHistory,
            ),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: scrollController,
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
                    border: Border.all(color: Pallete.border(context)),
                    color: Pallete.surface(context),
                    borderRadius: BorderRadius.circular(
                      20,
                    ).copyWith(topLeft: Radius.zero),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      "Good Morning,what task can I do for you?",
                      style: TextStyle(
                        color: Pallete.fontColor(context),
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
                      if (message.text.isNotEmpty)
                        _ChatBubble(
                          message: message,
                          onEdit: message.role == ChatRole.user
                              ? () => editMessage(message)
                              : null,
                        )
                      else if (isProcessing)
                        const _ThinkingBubble(),
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
                    color: Pallete.fontColor(context),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  enabled: !isProcessing,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTypedMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,
                    fillColor: Pallete.surface(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Pallete.border(context)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                color: Pallete.firstSuggestionBoxColor,
                onPressed: isProcessing ? null : _sendTypedMessage,
              ),
            ],
          ),
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
              await sendMessage(lastWords);
            } else {
              await startListening();
            }
          },
          child: isProcessing
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: const CircularProgressIndicator(
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
  final VoidCallback? onEdit;

  const _ChatBubble({required this.message, this.onEdit});

  Future<void> _showActions(BuildContext context) async {
    final isUser = message.role == ChatRole.user;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            if (isUser)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit & resend'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit?.call();
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(ClipboardData(text: message.text));
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  SharePlus.instance.share(ShareParams(text: message.text));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActions(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? Pallete.firstSuggestionBoxColor
                : Pallete.surface(context),
            border: isUser
                ? null
                : Border.all(color: Pallete.border(context)),
            borderRadius: BorderRadius.circular(18).copyWith(
              topLeft: isUser ? null : Radius.zero,
              topRight: isUser ? Radius.zero : null,
            ),
          ),
          child: isUser
              ? Text(
                  message.text,
                  style: const TextStyle(
                    color: Pallete.mainFontColor,
                    fontSize: 16,
                    fontFamily: 'Cera Pro',
                  ),
                )
              : MarkdownBody(
                  data: message.text,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: TextStyle(
                          color: Pallete.fontColor(context),
                          fontSize: 16,
                          fontFamily: 'Cera Pro',
                        ),
                      ),
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
          color: Pallete.surface(context),
          border: Border.all(color: Pallete.border(context)),
          borderRadius: BorderRadius.circular(18).copyWith(topLeft: Radius.zero),
        ),
        child: SizedBox(
          width: 20,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Pallete.fontColor(context),
          ),
        ),
      ),
    );
  }
}
