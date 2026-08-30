# Auraly - Voice Assistant App

Auraly is a Flutter-based voice assistant app that listens to your voice (or takes typed input) and responds intelligently, powered by Google Gemini via Firebase AI Logic.

---
## Features

- Sign in with Google - no API key to manage, Gemini access comes through your account via Firebase
- Voice recognition using [`speech_to_text`], with a typed-message fallback
- Text-to-Speech using [`flutter_tts`], with adjustable rate, pitch, and voice
- Streamed, markdown-rendered responses powered by Google Gemini
- Conversation history side panel: switch between, delete, or share past chats
- Dark mode and multi-language support
- Animated UI components using [`animate_do`]

---
## UI Preview

Here is the home screen UI of the app:

![Home Screen](screenshots/home_page.png)

---
## How to Run

1. Run `flutter pub get`.
2. Run `flutter run`.
3. On first launch, grant microphone access, then sign in with your Google account.

No API keys or `.env` files are needed to run this locally - authentication and Gemini access both flow through the Firebase project already wired up in `lib/firebase_options.dart`.

### Testing on a debug build

Firebase App Check enforces that only genuine app builds can call Gemini. Debug builds use App Check's debug provider, which requires a one-time step per device/browser:

1. Run the app; look for a log line like `Enter this debug secret into the allow list: XXXXXXXX-...` (Android: `adb logcat | grep -i AppCheck`; web: browser DevTools console).
2. Add that token in [Firebase Console → App Check → Manage debug tokens](https://console.firebase.google.com/project/auraly-voice-assistant/appcheck) for the relevant app.

Release builds don't need this - they use Play Integrity (Android), App Attest (iOS), and reCAPTCHA Enterprise (web) automatically.

---
## Configuration

`lib/app_config.dart` holds public client identifiers (currently just the reCAPTCHA Enterprise site key used for web App Check). These are safe to commit - reCAPTCHA site keys and Firebase's own config in `firebase_options.dart` are meant to be embedded in client code, unlike secret keys. If you fork this project, replace them with your own project's values.

### One-time Firebase setup (already done for this repo)

This project is wired to a Firebase project (`auraly-voice-assistant`). If you fork this repo or want your own backend:

1. Run `flutterfire configure` to point it at your own Firebase project.
2. In the [Firebase Console](https://console.firebase.google.com) → Authentication → Sign-in method, enable **Google** as a sign-in provider.
3. In the Firebase Console → Build → AI Logic, set up the **Gemini Developer API** backend (has a free tier).
4. In the Firebase Console → App Check, register each app (Android/iOS/Web) with an attestation provider (Play Integrity, App Attest, reCAPTCHA Enterprise respectively), and update `lib/app_config.dart` with your own reCAPTCHA site key.
5. For Android, add your debug and release SHA-1/SHA-256 fingerprints under Project Settings → Your apps (get the debug one with `cd android && ./gradlew signingReport`).

---
## Deploying the web build

The live deployment is at https://auraly-voice-assistant.vercel.app.

**Always use `./deploy_web.sh` to deploy** - never run `vercel --prod` directly from the project root. This project's source is Dart/Flutter, which Vercel cannot build; only the compiled output in `build/web` is deployable. Running `vercel` from the repo root uploads the Dart source instead and breaks the site with a 404.

```
./deploy_web.sh
```

This builds the web release (with the service worker disabled, so browsers always pick up new deploys) and deploys `build/web` in one step.

Note: the Vercel project's GitHub auto-deploy integration is intentionally disconnected - pushing to `main` does **not** redeploy the site. Deploys only happen when you explicitly run the script above.
