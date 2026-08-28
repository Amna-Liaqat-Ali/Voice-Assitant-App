# Auraly - Voice Assistant App

Auraly is a Flutter-based voice assistant app that listens to your voice (or takes typed input) and responds intelligently, powered by Google Gemini via Firebase AI Logic.

---
## Features

- Sign in with Google - no API key to manage, Gemini access comes through your account via Firebase
- Voice recognition using [`speech_to_text`], with a typed-message fallback
- Text-to-Speech using [`flutter_tts`], with adjustable rate, pitch, and voice
- Streamed, markdown-rendered responses powered by Google Gemini
- Conversation history side panel: switch, delete, or share past chats
- Dark mode and multi-language support
- Animated UI components using [`animate_do`]

---
## UI Preview

Here is the home screen UI of the app:

![Home Screen](screenshots/home_page.png)

## How to Run

1. Run `flutter pub get`.
2. Run `flutter run`.
3. On first launch, grant microphone access, then sign in with your Google account.

### One-time Firebase setup (already done for this repo)

This project is wired to a Firebase project (`auraly-voice-assistant`) via `lib/firebase_options.dart`. If you fork this repo or want your own backend:

1. Run `flutterfire configure` to point it at your own Firebase project.
2. In the [Firebase Console](https://console.firebase.google.com) → Authentication → Sign-in method, enable **Google** as a sign-in provider.
3. In the Firebase Console → Build → AI Logic, set up the **Gemini Developer API** backend (has a free tier).
4. For Android, add your debug and release SHA-1/SHA-256 fingerprints under Project Settings → Your apps (get the debug one with `cd android && ./gradlew signingReport`).

## Deploying the web build

The live deployment is at https://auraly-voice-assistant.vercel.app.

**Always use `./deploy_web.sh` to deploy** - never run `vercel --prod` directly from the project root. This project's source is Dart/Flutter, which Vercel cannot build; only the compiled output in `build/web` is deployable. Running `vercel` from the repo root uploads the Dart source instead and breaks the site with a 404.

```
./deploy_web.sh
```

This builds the web release and deploys `build/web` in one step.
