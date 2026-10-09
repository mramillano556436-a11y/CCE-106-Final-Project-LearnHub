import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth and Google Sign-In.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static bool _googleReady = false;

  static Future<void> init() async {
    try {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    } catch (e) {
      debugPrint('Google Sign-In unavailable: $e');
    }
  }

  /// Google Sign-In's native flow is available on Android/iOS, not Windows.
  static bool get googleSupported => _googleReady && GoogleSignIn.instance.supportsAuthenticate();

  static User? get currentUser => _auth.currentUser;

  static Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  static Future<User> createAccount(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    await cred.user!.updateDisplayName(name);
    return cred.user!;
  }

  static Future<void> signInWithGoogle() async {
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw FirebaseAuthException(code: 'missing-id-token');
    await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
  }

  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  static bool get hasPasswordLogin =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

  static Future<void> changePassword(String newPassword) =>
      _auth.currentUser!.updatePassword(newPassword);

  /// Sends a confirmation link to the new address; the change applies after it is clicked.
  static Future<void> changeEmail(String newEmail) =>
      _auth.currentUser!.verifyBeforeUpdateEmail(newEmail.trim());

  static Future<void> signOut() async {
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  /// Converts auth errors into messages a user can act on.
  static String describeError(Object error) {
    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => 'Google sign-in was cancelled. If you did not cancel it, '
            "the app's SHA-1 fingerprint is probably missing from Firebase or google-services.json is out of date.",
        _ => 'Google sign-in failed (${error.code.name}). '
            'Check that the SHA-1 fingerprint is added in Firebase.',
      };
    }
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for that email. Try logging in.',
        'weak-password' => 'Password must be at least 6 characters.',
        'requires-recent-login' => 'For security, log out and log back in, then try again.',
        'network-request-failed' => 'No internet connection.',
        'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
        _ => error.message ?? 'Authentication failed (${error.code}).',
      };
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'You do not have permission to do that.';
    }
    if (error is StateError) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }
}
