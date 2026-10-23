import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../app/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  CHANGE PHONE NUMBER — new number entry → OTP verify (2-step sheet)
// ═══════════════════════════════════════════════════════════════════
// Phone badalne ke liye naye number par OTP verify karna zaroori hai —
// backend `pendingPhone` par save karke tabhi live `phone` update karta
// hai jab OTP sahi verify ho jaaye.
//
// Worker aur vendor dono yahi sheet use karte hain — endpoints
// (/profile/phone/send-otp, /profile/phone/verify-otp) role-agnostic
// hain, sirf logged-in user chahiye. [onUpdated] optional hai — jis
// screen ko apna local phone state refresh karna ho wo pass kar de.
void showChangePhoneSheet(
  BuildContext context, {
  void Function(String newPhone)? onUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ChangePhoneSheet(onUpdated: onUpdated),
  );
}

class _ChangePhoneSheet extends StatefulWidget {
  final void Function(String newPhone)? onUpdated;
  const _ChangePhoneSheet({this.onUpdated});

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  final _profileApi = ProfileApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  int _step = 1; // 1 = enter number, 2 = enter OTP
  bool _isSending = false;
  bool _isVerifying = false;
  int _resendSeconds = 0;
  String _confirmedPhone = '';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Sheet khulte hi keyboard turant aa jaaye — auto-focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendSeconds = 30);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      AppSnackbar.error(message: 'enter_valid_mobile_error'.tr);
      return;
    }
    setState(() => _isSending = true);
    final res = await _profileApi.sendPhoneChangeOtp(phone);
    if (!mounted) return;
    setState(() => _isSending = false);
    if (res.success) {
      _otpCtrl.clear();
      setState(() {
        _confirmedPhone = phone;
        _step = 2;
      });
      _startCountdown();
      AppSnackbar.success(message: res.message ?? 'otp_sent_success'.tr);
    } else {
      AppSnackbar.error(message: res.message ?? 'otp_send_failed'.tr);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != AppConfig.otpLength) {
      AppSnackbar.error(message: 'enter_six_digit_otp_error'.tr);
      return;
    }
    setState(() => _isVerifying = true);
    final res = await _profileApi.verifyPhoneChangeOtp(otp);
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (res.success) {
      _countdownTimer?.cancel();
      widget.onUpdated?.call(_confirmedPhone);
      Navigator.of(context).pop();
      AppSnackbar.success(
          message: res.message ?? 'phone_number_updated_success'.tr);
    } else {
      AppSnackbar.error(message: res.message ?? 'otp_verify_failed'.tr);
    }
  }

  void _backToPhoneStep() {
    _countdownTimer?.cancel();
    setState(() => _step = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _phoneFocus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.lg,
        right: AppDimens.lg,
        top: AppDimens.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimens.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _step == 1 ? 'change_phone_number'.tr : 'verify_new_number_title'.tr,
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _step == 1
                ? 'change_phone_subtitle'.tr
                : 'otp_sent_to_number'.trParams({'phone': _confirmedPhone}),
            style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (_step == 1) ...[
            Text('new_mobile_number_label'.tr,
                style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w500,
                    c: AppColors.textSecondary)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.selectionBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppDimens.radiusMd),
                        bottomLeft: Radius.circular(AppDimens.radiusMd),
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('+91',
                        style: KTextStyle.poppins(
                            fs: 14,
                            fw: FontWeight.w700,
                            c: AppColors.primary)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      focusNode: _phoneFocus,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onSubmitted: (_) => _sendOtp(),
                      style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        hintStyle:
                            KTextStyle.poppins(fs: 14, c: AppColors.textHint),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppDimens.radiusMd),
                            bottomRight: Radius.circular(AppDimens.radiusMd),
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppDimens.radiusMd),
                            bottomRight: Radius.circular(AppDimens.radiusMd),
                          ),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppDimens.radiusMd),
                            bottomRight: Radius.circular(AppDimens.radiusMd),
                          ),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'send_otp'.tr,
              isLoading: _isSending,
              onTap: _isSending ? null : _sendOtp,
            ),
          ] else ...[
            Center(
              child: Pinput(
                length: AppConfig.otpLength,
                controller: _otpCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                onCompleted: (_) => _verifyOtp(),
                defaultPinTheme: PinTheme(
                  width: 44,
                  height: 50,
                  textStyle: KTextStyle.poppins(fs: 18, fw: FontWeight.w700),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 44,
                  height: 50,
                  textStyle: KTextStyle.poppins(fs: 18, fw: FontWeight.w700),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            CustomButton(
              label: 'verify_update_btn'.tr,
              isLoading: _isVerifying,
              onTap: _isVerifying ? null : _verifyOtp,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isSending ? null : _backToPhoneStep,
                  child: Text('change_number_btn'.tr,
                      style: KTextStyle.poppins(
                          fs: 12.5,
                          fw: FontWeight.w600,
                          c: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed:
                      (_isSending || _resendSeconds > 0) ? null : _sendOtp,
                  child: Text(
                    _resendSeconds > 0
                        ? 'resend_in_seconds'
                            .trParams({'seconds': '$_resendSeconds'})
                        : 'resend_otp'.tr,
                    style: KTextStyle.poppins(
                        fs: 12.5,
                        fw: FontWeight.w600,
                        c: _resendSeconds > 0
                            ? AppColors.textHint
                            : AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
