import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/HomePage.dart';
import 'package:voice_assistant/firebase_options.dart';
import 'package:voice_assistant/google_auth_service.dart';
import 'package:voice_assistant/login_page.dart';
import 'package:voice_assistant/onboarding_page.dart';
import 'package:voice_assistant/pallete.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //fired without awaiting: activation can hang (e.g. web without a reCAPTCHA
  //site key configured yet) and must never block the app from rendering
  unawaited(_activateAppCheck());
  runApp(const MyApp());
}

//required by Firebase AI Logic (Gemini) to verify requests come from this
//genuine app build, not a script hitting the backend directly.
//TODO: swap WebDebugProvider for ReCaptchaV3Provider once a reCAPTCHA site
//key is registered in Firebase Console for production use.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider()
          : AppleAppAttestProvider(),
      providerWeb: WebDebugProvider(),
    );
  } catch (_) {
    // Gemini calls will surface their own error if App Check is unavailable.
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _themeModeKey = 'theme_mode';
  static const _onboardingCompleteKey = 'onboarding_complete';
  final _authService = GoogleAuthService();
  ThemeMode themeMode = ThemeMode.light;
  bool? onboardingComplete;
  bool? isSignedIn;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadOnboardingStatus();
    setState(() => isSignedIn = _authService.currentUser != null);
    _authService.authStateChanges.listen(
      (user) => setState(() => isSignedIn = user != null),
    );
  }

  Future<void> _signOut() => _authService.signOut();

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
      home: switch ((onboardingComplete, isSignedIn)) {
        (null, _) || (_, null) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        (false, _) => OnboardingPage(onComplete: _completeOnboarding),
        (true, false) => LoginPage(
          onLoggedIn: () => setState(() => isSignedIn = true),
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
