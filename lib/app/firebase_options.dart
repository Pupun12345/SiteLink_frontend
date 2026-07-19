// ═══════════════════════════════════════════════════════════════════
//  DEFAULT FIREBASE OPTIONS
// ═══════════════════════════════════════════════════════════════════
// Values android/app/google-services.json se liye gaye hain
// (project: sitelink-af317, package com.sitelink.sitelink — build.gradle.kts
// ka applicationId isi se match karta hai). Android-first setup — iOS/macOS/web
// ke liye abhi config nahi hai, isliye un platforms pe clear error throw hota hai.
//
// NOTE: is google-services.json me `oauth_client` khaali hai — matlab
// Firebase console me is app (package com.sitelink.sitelink) ke liye abhi
// SHA-1/SHA-256 fingerprint register nahi hai. FCM push notifications isse
// affect nahi hote, lekin Google Sign-In tab tak kaam nahi karega jab tak
// SHA-1 Firebase console me add na ho aur google-services.json dobara
// download na ho.
//
// Naye platform add karne ke liye `flutterfire configure` chalao ya
// neeche aur FirebaseOptions add karo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web Firebase config nahi hai. `flutterfire configure` chalao.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase config nahi hai. GoogleService-Info.plist add karke '
          '`flutterfire configure` chalao.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions sirf Android ke liye configured hai '
          '(platform: $defaultTargetPlatform).',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMxzyVSIzRzxKbi5mmevejccsptfjtc7A',
    appId: '1:162479249381:android:5d94d32fbe70d96081c10c',
    messagingSenderId: '162479249381',
    projectId: 'sitelink-af317',
    storageBucket: 'sitelink-af317.firebasestorage.app',
  );
}
