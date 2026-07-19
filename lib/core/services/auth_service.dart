import 'package:firebase_auth/firebase_auth.dart';
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

    final account = await GoogleSignIn.instance.authenticate();

    // v7 me authentication se sirf idToken milta hai
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google sign-in se token nahi mila.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCred = await _auth.signInWithCredential(credential);
    final firebaseToken = await userCred.user?.getIdToken();
    if (firebaseToken == null) {
      throw const AuthException('Firebase authentication fail ho gaya.');
    }

    return GoogleAuthResult(
      firebaseIdToken: firebaseToken,
      displayName: account.displayName,
      email: account.email,
    );
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
