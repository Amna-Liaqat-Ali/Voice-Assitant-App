import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  //GoogleSignIn.instance is a singleton shared across every GoogleAuthService
  //object, so initialization state must be too - otherwise a fresh instance
  //(e.g. a new LoginPage after sign-out) calls initialize() a second time,
  //which throws on web because the underlying completer is already resolved
  static Future<void>? _initializeFuture;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //web doesn't support the imperative authenticate() flow; it requires
  //rendering Google's own sign-in button instead
  bool get supportsButtonlessSignIn => _googleSignIn.supportsAuthenticate();

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  Future<void> ensureInitialized() {
    return _initializeFuture ??= _googleSignIn.initialize();
  }

  //links an already-authenticated Google account (from either the
  //authenticate() flow or a rendered sign-in button) to Firebase Auth
  Future<void> linkToFirebase(GoogleSignInAccount account) async {
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  //signs the user in with their Google account and links it to Firebase Auth,
  //so Firebase AI Logic can call Gemini on their behalf without an API key.
  //Only supported on platforms where supportsButtonlessSignIn is true.
  Future<void> signIn() async {
    await ensureInitialized();
    final account = await _googleSignIn.authenticate();
    await linkToFirebase(account);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
