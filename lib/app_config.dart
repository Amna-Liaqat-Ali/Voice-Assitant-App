//Public client identifiers used to configure third-party services.
//
//None of these are secrets: reCAPTCHA site keys (unlike secret keys) are
//designed to be embedded in client code and are safe to commit. Firebase's
//own config lives separately in firebase_options.dart (also public by
//design - see https://firebase.google.com/docs/projects/api-keys).
//
//This file exists purely to keep such identifiers in one place instead of
//scattered inline through the codebase.
class AppConfig {
  //Firebase Console > App Check > voice_assistant (web) > reCAPTCHA Enterprise
  static const recaptchaEnterpriseSiteKey =
      '6LfTtp0tAAAAADJhcpWRPxTQQGhzkHbioQZhBPwv';
}
