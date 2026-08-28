import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_assistant/pallete.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _requesting = false;

  Future<void> _getStarted() async {
    setState(() => _requesting = true);
    //triggers the OS microphone permission prompt
    await SpeechToText().initialize();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic,
                size: 96,
                color: Pallete.firstSuggestionBoxColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Auraly',
                style: TextStyle(
                  fontFamily: 'Cera Pro',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Pallete.fontColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Auraly listens to your voice and answers using Google '
                'Gemini. To do that, it needs access to your microphone.',
                style: TextStyle(
                  fontSize: 16,
                  color: Pallete.fontColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _requesting ? null : _getStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.firstSuggestionBoxColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: _requesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
