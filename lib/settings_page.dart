import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/pallete.dart';

const _localePrefKey = 'assistant_locale';
const _speechRatePrefKey = 'speech_rate';
const _speechPitchPrefKey = 'speech_pitch';
const supportedLocales = {
  'en-US': 'English (US)',
  'es-ES': 'Spanish',
  'fr-FR': 'French',
  'hi-IN': 'Hindi',
  'ur-PK': 'Urdu',
};
const _defaultLocale = 'en-US';
const _defaultSpeechRate = 0.5;
const _defaultSpeechPitch = 1.0;

class SettingsPage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onClearChat;

  const SettingsPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onClearChat,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  String _selectedLocale = _defaultLocale;
  double _speechRate = _defaultSpeechRate;
  double _speechPitch = _defaultSpeechPitch;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _selectedLocale = prefs.getString(_localePrefKey) ?? _defaultLocale;
      _speechRate = prefs.getDouble(_speechRatePrefKey) ?? _defaultSpeechRate;
      _speechPitch =
          prefs.getDouble(_speechPitchPrefKey) ?? _defaultSpeechPitch;
      _version = '${info.version} (${info.buildNumber})';
      _loading = false;
    });
  }

  Future<void> _setLocale(String value) async {
    setState(() => _selectedLocale = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, value);
  }

  Future<void> _setSpeechRate(double value) async {
    setState(() => _speechRate = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRatePrefKey, value);
  }

  Future<void> _setSpeechPitch(double value) async {
    setState(() => _speechPitch = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechPitchPrefKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionTitle('Appearance'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark mode'),
                  value: widget.themeMode == ThemeMode.dark,
                  onChanged: (_) => widget.onToggleTheme(),
                ),
                const SizedBox(height: 16),

                _SectionTitle('Language'),
                DropdownButton<String>(
                  value: _selectedLocale,
                  isExpanded: true,
                  items: [
                    for (final entry in supportedLocales.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) _setLocale(value);
                  },
                ),
                const SizedBox(height: 16),

                _SectionTitle('Voice'),
                Text(
                  'Speech rate',
                  style: TextStyle(color: Pallete.fontColor(context)),
                ),
                Slider(
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (value) => setState(() => _speechRate = value),
                  onChangeEnd: _setSpeechRate,
                ),
                Text(
                  'Pitch',
                  style: TextStyle(color: Pallete.fontColor(context)),
                ),
                Slider(
                  value: _speechPitch,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (value) => setState(() => _speechPitch = value),
                  onChangeEnd: _setSpeechPitch,
                ),
                const SizedBox(height: 16),

                _SectionTitle('Conversation'),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear chat history'),
                  onPressed: () {
                    widget.onClearChat();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat history cleared')),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _SectionTitle('About'),
                Text(
                  'Auraly',
                  style: TextStyle(color: Pallete.fontColor(context)),
                ),
                Text(
                  'Version $_version',
                  style: TextStyle(color: Pallete.fontColor(context)),
                ),
                Text(
                  'Powered by Google Gemini',
                  style: TextStyle(color: Pallete.fontColor(context)),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Cera Pro',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Pallete.fontColor(context),
        ),
      ),
    );
  }
}

//the BCP-47 locale to use for speech-to-text and text-to-speech
Future<String> loadAssistantLocale() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_localePrefKey) ?? _defaultLocale;
}

//how fast the assistant speaks, 0.1 (slow) to 1.0 (fast)
Future<double> loadSpeechRate() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_speechRatePrefKey) ?? _defaultSpeechRate;
}

//the assistant's voice pitch, 0.5 (low) to 2.0 (high)
Future<double> loadSpeechPitch() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(_speechPitchPrefKey) ?? _defaultSpeechPitch;
}
