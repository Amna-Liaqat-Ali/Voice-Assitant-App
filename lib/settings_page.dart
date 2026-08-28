import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/pallete.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _apiKeyPrefKey = 'gemini_api_key_override';
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedKey();
  }

  Future<void> _loadSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = prefs.getString(_apiKeyPrefKey) ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await prefs.remove(_apiKeyPrefKey);
    } else {
      await prefs.setString(_apiKeyPrefKey, key);
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gemini API Key',
                    style: TextStyle(
                      fontFamily: 'Cera Pro',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Pallete.fontColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave blank to use the key bundled with the app. '
                    'Get a free key at aistudio.google.com/apikey.',
                    style: TextStyle(color: Pallete.fontColor(context)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste your Gemini API key',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ),
    );
  }
}

//looks up the user's own key if they've set one, otherwise null
Future<String?> loadApiKeyOverride() async {
  final prefs = await SharedPreferences.getInstance();
  final key = prefs.getString('gemini_api_key_override');
  return (key == null || key.isEmpty) ? null : key;
}
