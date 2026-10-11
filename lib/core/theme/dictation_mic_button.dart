import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/k_text_style.dart';
import '../services/speech_input_service.dart';
import 'app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  DICTATION MIC BUTTON — kisi bhi TextField me bolke likhne ke liye
// ═══════════════════════════════════════════════════════════════════
// Tap → sunna shuru (mic laal + pulse), dobara tap → band. Jo bola wo
// field me pehle se likhe text ke aage jud jaata hai — purana text
// mitta nahi.
class DictationMicButton extends StatefulWidget {
  final TextEditingController controller;

  /// Bolna khatam hone par focus wapas field pe — user turant edit kar sake.
  final FocusNode? focusNode;

  const DictationMicButton({
    super.key,
    required this.controller,
    this.focusNode,
  });

  @override
  State<DictationMicButton> createState() => _DictationMicButtonState();
}

class _DictationMicButtonState extends State<DictationMicButton>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechInputService.instance;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool _listening = false;

  /// Sunna shuru karte waqt field me jo text tha. Recognizer har baar
  /// poora vaakya dobara bhejta hai, isliye append karne ke bajaye
  /// "base + jo abhi bola" set karte hain — warna text repeat ho jaata.
  String _baseText = '';

  @override
  void dispose() {
    _pulse.dispose();
    // Screen chhodte waqt mic khula na reh jaaye
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _stop();
      return;
    }

    final existing = widget.controller.text.trimRight();
    _baseText = existing.isEmpty ? '' : '$existing ';

    // State pehle set karo — recognizer kabhi-kabhi turant 'done' bhej
    // deta hai, aur tab tak `_listening` false hota to UI atak jaata.
    setState(() => _listening = true);
    _pulse.repeat(reverse: true);

    final started = await _speech.start(
      onResult: (text, isFinal) {
        if (!mounted) return;
        final combined = '$_baseText$text';
        widget.controller.value = TextEditingValue(
          text: combined,
          // Caret hamesha aakhir me — warna har partial result pe
          // cursor shuru me kood jaata hai.
          selection: TextSelection.collapsed(offset: combined.length),
        );
      },
      onDone: () {
        if (mounted && _listening) _stop();
      },
    );

    if (!started) {
      _pulse.stop();
      _pulse.value = 0;
      if (mounted) setState(() => _listening = false);
      _showFailure();
    }
  }

  /// Har wajah ka alag jawab — "kuch gadbad hai" bolne se user kuch
  /// nahi kar paata.
  void _showFailure() {
    switch (_speech.lastFailure) {
      case SpeechUnavailableReason.permissionPermanentlyDenied:
        // Yahan snackbar bekaar hai — permission ab sirf Settings se
        // milegi, isliye seedha wahan bhejne wala dialog.
        Get.dialog(
          AlertDialog(
            title: Text('mic_permission_title'.tr,
                style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
            content: Text('mic_permission_blocked_message'.tr,
                style:
                    KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: Get.back, child: Text('cancel_label'.tr)),
              TextButton(
                onPressed: () {
                  Get.back();
                  _speech.openSettings();
                },
                child: Text('open_settings_label'.tr,
                    style: KTextStyle.poppins(
                        fs: 13,
                        fw: FontWeight.w600,
                        c: AppColors.primary)),
              ),
            ],
          ),
        );
      case SpeechUnavailableReason.permissionDenied:
        AppSnackbar.error(message: 'mic_permission_denied_error'.tr);
      case SpeechUnavailableReason.noRecognizer:
      case null:
        AppSnackbar.error(message: 'mic_unavailable_error'.tr);
    }
  }

  Future<void> _stop() async {
    await _speech.stop();
    _pulse.stop();
    _pulse.value = 0;
    if (mounted) setState(() => _listening = false);
    widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final color = _listening ? AppColors.error : AppColors.primary;

    return Semantics(
      button: true,
      label: _listening ? 'listening_label'.tr : 'tap_to_speak_label'.tr,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1 + 0.15 * _pulse.value),
              shape: BoxShape.circle,
              border: _listening
                  ? Border.all(color: color.withOpacity(0.5), width: 1.5)
                  : null,
            ),
            child: child,
          ),
          child: Icon(
            _listening ? Icons.stop_rounded : Icons.mic_rounded,
            color: color,
            size: 18,
          ),
        ),
      ),
    );
  }
}
