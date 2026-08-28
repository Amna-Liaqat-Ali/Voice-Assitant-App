import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //signs the user in with their Google account and links it to Firebase Auth,
  //so Firebase AI Logic can call Gemini on their behalf without an API key
  Future<void> signIn() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate();
    final authentication = account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
