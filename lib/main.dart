import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/HomePage.dart';
import 'package:voice_assistant/api_key_store.dart';
import 'package:voice_assistant/login_page.dart';
import 'package:voice_assistant/onboarding_page.dart';
import 'package:voice_assistant/pallete.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _themeModeKey = 'theme_mode';
  static const _onboardingCompleteKey = 'onboarding_complete';
  ThemeMode themeMode = ThemeMode.light;
  bool? onboardingComplete;
  bool? hasApiKey;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadOnboardingStatus();
    _loadApiKeyStatus();
  }

  Future<void> _loadApiKeyStatus() async {
    final key = await loadApiKey();
    setState(() => hasApiKey = key != null && key.isNotEmpty);
  }

  Future<void> _signOut() async {
    await clearApiKey();
    setState(() => hasApiKey = false);
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeModeKey) ?? false;
    setState(() => themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(
      () => onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
    setState(() => onboardingComplete = true);
  }

  Future<void> toggleThemeMode() async {
    final isDark = themeMode == ThemeMode.dark;
    setState(() => themeMode = isDark ? ThemeMode.light : ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, !isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auraly',
      themeMode: themeMode,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.whiteColor,
        appBarTheme: AppBarTheme(backgroundColor: Pallete.whiteColor),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.darkBackgroundColor,
        appBarTheme: AppBarTheme(backgroundColor: Pallete.darkBackgroundColor),
      ),
      home: switch ((onboardingComplete, hasApiKey)) {
        (null, _) || (_, null) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        (false, _) => OnboardingPage(onComplete: _completeOnboarding),
        (true, false) => LoginPage(
          onLoggedIn: () => setState(() => hasApiKey = true),
        ),
        (true, true) => Homepage(
          onToggleTheme: toggleThemeMode,
          themeMode: themeMode,
          onSignOut: _signOut,
        ),
      },
    );
  }
}
