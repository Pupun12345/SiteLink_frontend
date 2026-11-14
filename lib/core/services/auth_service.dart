import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../app/config/app_config.dart';

// ═══════════════════════════════════════════════════════════════════
//  AUTH SERVICE — Google + Firebase auth ka single source of truth
// ═══════════════════════════════════════════════════════════════════
// Google sign-in flow yahin centralize hai. Controllers sirf
// `AuthService.instance.signInWithGoogle()` call karte hain — koi
// hardcoded clientId ya repeated `GoogleSignIn.initialize()` nahi.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool _googleInitialized = false;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Current Firebase user (null agar logged out).
  User? get currentUser => _auth.currentUser;

  /// App start pe ek baar call karo (main.dart). google_sign_in v7 ko
  /// `initialize()` ek hi baar chahiye — idempotent guard ke saath.
  Future<void> init() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Poora Google → Firebase handshake.
  /// Backend ko bhejne ke liye Firebase ID token + basic user info deta hai.
  /// User cancel ya failure pe [AuthException] / provider exception throw karega.
  Future<GoogleAuthResult> signInWithGoogle() async {
    await init(); // safety — agar main me init miss ho jaye

    try {
      debugPrint('[GOOGLE_DEBUG] Starting authentication');

      final account = await GoogleSignIn.instance.authenticate();

      debugPrint('[GOOGLE_DEBUG] Account selected');
      debugPrint('[GOOGLE_DEBUG] Email: ${account.email}');

      final googleAuth = account.authentication;
      debugPrint(
        '[GOOGLE_DEBUG] ID token received: ${googleAuth.idToken != null}',
      );

      if (googleAuth.idToken == null) {
        throw const AuthException('Google sign-in se token nahi mila.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('[GOOGLE_DEBUG] Calling Firebase');

      final userCred = await _auth.signInWithCredential(credential);
      debugPrint(
        '[GOOGLE_DEBUG] Firebase success: ${userCred.user?.uid}',
      );

      final firebaseToken = await userCred.user?.getIdToken();
      if (firebaseToken == null) {
        throw const AuthException('Firebase authentication fail ho gaya.');
      }

      debugPrint('[GOOGLE_DEBUG] Firebase ID token generated: ${firebaseToken.isNotEmpty}');

      return GoogleAuthResult(
        firebaseIdToken: firebaseToken,
        displayName: account.displayName,
        email: account.email,
      );
    } on GoogleSignInException catch (e, st) {
      debugPrint('[GOOGLE_DEBUG] Error code: ${e.code}');
      debugPrint('[GOOGLE_DEBUG] Description: ${e.description}');
      debugPrintStack(stackTrace: st);
      throw AuthException('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FIREBASE_DEBUG] Code: ${e.code}');
      debugPrint('[FIREBASE_DEBUG] Message: ${e.message}');
      debugPrintStack(stackTrace: st);
      throw AuthException('Firebase authentication failed: ${e.message ?? e.code}');
    } catch (e, st) {
      debugPrint('[OTHER_DEBUG] $e');
      debugPrintStack(stackTrace: st);
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  /// Firebase + Google dono se sign out.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}

/// signInWithGoogle ka result.
class GoogleAuthResult {
  final String firebaseIdToken;
  final String? displayName;
  final String? email;

  const GoogleAuthResult({
    required this.firebaseIdToken,
    this.displayName,
    this.email,
  });
}

/// Auth layer ke controlled errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
