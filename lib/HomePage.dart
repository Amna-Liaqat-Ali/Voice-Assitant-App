import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/FeatureBox.dart';
import 'package:voice_assistant/openai_service.dart';
import 'package:voice_assistant/pallete.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final speechToText = SpeechToText();
  String lastWords = '';
  final OpenAIService openAIService = OpenAIService();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSpeechToText();
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

  //when leaves screen it is called to prevent resource leak
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    speechToText.stop();
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
            Stack(
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
            //chat
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: EdgeInsets.symmetric(horizontal: 40).copyWith(top: 30),
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

            Container(
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

            //feature boxes
            Featurebox(
              color: Pallete.firstSuggestionBoxColor,
              headerText: 'ChatGPT',
              descText: 'A smarter way to stay organized and informed with GPT',
            ),
            SizedBox(height: 10),
            Featurebox(
              color: Pallete.secondSuggestionBoxColor,
              headerText: 'Dell-E',
              descText:
                  'Get inspired and stay creative with your personal assitant powerded by Dell-E',
            ),
            SizedBox(height: 10),
            Featurebox(
              color: Pallete.thirdSuggestionBoxColor,
              headerText: 'Smart Voice Assistant',
              descText:
                  'Get the best of both worlds with a voice assistant powerded by Dell-E and chatgpt',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Pallete.firstSuggestionBoxColor,
        onPressed: () async {
          //when u open app for first time nd clicks on button
          if (await speechToText.hasPermission && speechToText.isNotListening) {
            await startListening();
            //app is already listening
          } else if (speechToText.isListening) {
            //check weather user is asking for question or generation of image
            final speech = await openAIService.isArtAPI(lastWords);
            print(speech);
            await stopListening();
          } else {
            initSpeechToText();
          }
        },
        child: Icon(Icons.mic),
      ),
    );
  }
}
