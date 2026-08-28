import 'package:flutter/material.dart';
import 'package:voice_assistant/api_key_store.dart';
import 'package:voice_assistant/pallete.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginPage({super.key, required this.onLoggedIn});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please enter your API key');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await saveApiKey(key);
    widget.onLoggedIn();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.key_outlined,
                size: 72,
                color: Pallete.firstSuggestionBoxColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Connect your Gemini account',
                style: TextStyle(
                  fontFamily: 'Cera Pro',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Pallete.fontColor(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Auraly runs on your own free Gemini API key, so your usage '
                'and quota stay yours. Get one at aistudio.google.com/apikey, '
                'then paste it below. It is stored encrypted on this device only.',
                style: TextStyle(fontSize: 15, color: Pallete.fontColor(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Gemini API key',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.firstSuggestionBoxColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
