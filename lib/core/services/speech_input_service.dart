import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

// ═══════════════════════════════════════════════════════════════════
//  SPEECH INPUT SERVICE — bolke likhne (dictation) ka single wrapper
// ═══════════════════════════════════════════════════════════════════
// Device ka apna speech recognizer use hota hai (Android pe Google,
// iOS pe Siri) — koi API key ya backend call nahi. Plugin ko poore app
// me ek hi baar initialize karna hota hai, isliye yeh singleton hai.
class SpeechInputService {
  SpeechInputService._();
  static final SpeechInputService instance = SpeechInputService._();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// Kyun fail hua — UI isi ke hisaab se sahi message dikhata hai.
  SpeechUnavailableReason? lastFailure;

  bool get isListening => _speech.isListening;

  /// Mic permission khud maangte hain (speech_to_text ke bharose nahi) —
  /// usse "permanently denied" aur "device pe recognizer hi nahi" me farq
  /// nahi pata chalta, aur dono cases me user ko alag guidance chahiye.
  Future<bool> _ensurePermission() async {
    try {
      var status = await Permission.microphone.status;
      if (status.isGranted) return true;

      if (status.isPermanentlyDenied || status.isRestricted) {
        lastFailure = SpeechUnavailableReason.permissionPermanentlyDenied;
        return false;
      }

      status = await Permission.microphone.request();
      if (status.isGranted) return true;

      // Android pe "Don't allow" doosri baar dabane se status yahin
      // permanentlyDenied ho jaata hai — tab settings hi ekmatra raasta hai.
      lastFailure = status.isPermanentlyDenied
          ? SpeechUnavailableReason.permissionPermanentlyDenied
          : SpeechUnavailableReason.permissionDenied;
      return false;
    } on MissingPluginException {
      // Plugin ka native side register nahi hua — aksar tab hota hai jab
      // pubspec me plugin add karke sirf hot restart kiya ho. Mic feature
      // isliye band nahi karna chahiye: speech_to_text ka initialize()
      // khud bhi permission maang leta hai, bas usse permanently-denied
      // ka pata nahi chalta. Aage badhne do.
      debugPrint('[Speech] permission_handler not registered — full '
          'rebuild chahiye. speech_to_text ke fallback pe chal rahe hain.');
      return true;
    } catch (e) {
      debugPrint('[Speech] permission check failed: $e');
      return true;
    }
  }

  /// Permission mil jaane ke baad recognizer initialize. Idempotent —
  /// success hone par hi cache karte hain.
  Future<bool> _ensureInitialized() async {
    if (!await _ensurePermission()) return false;
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (e) => debugPrint('[Speech] error: ${e.errorMsg}'),
        onStatus: (s) => debugPrint('[Speech] status: $s'),
      );
      // Permission to hai, phir bhi fail — matlab device pe koi speech
      // recognition service hi nahi (kuch custom ROMs / GMS-less devices).
      if (!_initialized) lastFailure = SpeechUnavailableReason.noRecognizer;
      return _initialized;
    } catch (e) {
      debugPrint('[Speech] init failed: $e');
      lastFailure = SpeechUnavailableReason.noRecognizer;
      return false;
    }
  }

  /// Settings screen kholo taaki user mic permission on kar sake.
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('[Speech] openAppSettings failed: $e');
    }
  }

  /// Sunna shuru. [onResult] partial results ke saath baar-baar call hota
  /// hai (jo bola ja raha hai wo live dikhe), [onDone] tab jab recognizer
  /// khud ruk jaaye — silence ya timeout par.
  ///
  /// `false` return kare to [lastFailure] dekh lo.
  Future<bool> start({
    required void Function(String text, bool isFinal) onResult,
    required VoidCallback onDone,
  }) async {
    if (!await _ensureInitialized()) return false;
    if (_speech.isListening) return true;

    // listen() se PEHLE set karo — warna recognizer turant ruk jaaye
    // (jaise mic busy ho) to 'done' miss ho jaata hai aur UI hamesha
    // "Listening…" dikhata reh jaata hai.
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') onDone();
    };

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        // App ki chuni hui bhasha me hi sunta hai — Hindi user "मिस्त्री
        // का काम" bole to English recognizer usse kachra bana deta.
        localeId: await _localeId(),
        partialResults: true,
        cancelOnError: true,
        // dictation = lambe pause ke baad bhi sunta rahe, kyunki user
        // soch-soch kar bolta hai.
        listenMode: ListenMode.dictation,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 2),
      ),
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
    );
    return true;
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }

  /// App ki language ke hisaab se recognizer locale. Device pe wo locale
  /// support na ho to null — plugin device default use kar lega.
  Future<String?> _localeId() async {
    final wanted = Get.locale?.languageCode == 'hi' ? 'hi_IN' : 'en_IN';
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.replaceAll('-', '_') == wanted) return l.localeId;
      }
      // en_IN na mile to koi bhi English chalega
      final prefix = wanted.split('_').first;
      for (final l in locales) {
        if (l.localeId.startsWith(prefix)) return l.localeId;
      }
    } catch (_) {/* locales list na mile to default */}
    return null;
  }
}

enum SpeechUnavailableReason {
  /// User ne abhi "Deny" kiya — dobara maang sakte hain.
  permissionDenied,

  /// "Don't ask again" / iOS pe deny — ab sirf Settings se on hoga.
  permissionPermanentlyDenied,

  /// Permission to hai, par device pe speech recognition service nahi.
  noRecognizer,
}
