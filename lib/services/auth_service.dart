import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth       = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Current User ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static bool  get isLoggedIn  => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Email Sign Up ─────────────────────────────────────────────────────────
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      // Save display name
      await credential.user?.updateDisplayName(name.trim());
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Email Sign In ─────────────────────────────────────────────────────────
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password.trim(),
      );
      return AuthResult.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.error('Google sign-in was cancelled.');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Google sign-in failed. Please try again.');
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_firebaseError(e.code));
    } catch (e) {
      return AuthResult.error('Could not send reset email. Try again.');
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Firebase Error Messages ───────────────────────────────────────────────
  static String _firebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}

// ── Auth Result wrapper ───────────────────────────────────────────────────────
class AuthResult {
  final User? user;
  final String? errorMessage;
  final bool isSuccess;

  AuthResult._({this.user, this.errorMessage, required this.isSuccess});

  factory AuthResult.success(User? user) =>
      AuthResult._(user: user, isSuccess: true);

  factory AuthResult.error(String message) =>
      AuthResult._(errorMessage: message, isSuccess: false);
}