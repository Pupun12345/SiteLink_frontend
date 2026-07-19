import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/edit_vendor_profile_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  CHANGE PHONE NUMBER — new number entry → OTP verify (2-step sheet)
// ═══════════════════════════════════════════════════════════════════
// Phone badalne ke liye naye number par OTP verify karna zaroori hai —
// backend `pendingPhone` par save karke tabhi live `phone` update karta
// hai jab OTP sahi verify ho jaaye.
void showChangePhoneSheet(BuildContext context, EditVendorProfileController ctrl) {
  final phoneCtrl = TextEditingController();
  final otpCtrl   = TextEditingController();
  final step      = 1.obs; // 1 = enter number, 2 = enter OTP
  final isSending   = false.obs;
  final isVerifying = false.obs;
  final resendSeconds = 0.obs;
  final confirmedPhone = ''.obs;

  Timer? countdownTimer;
  void startCountdown() {
    resendSeconds.value = 30;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        t.cancel();
        resendSeconds.value = 0;
      } else {
        resendSeconds.value--;
      }
    });
  }

  Future<void> sendOtp() async {
    final phone = phoneCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      AppSnackbar.error(message: 'Sahi 10-digit mobile number daalein');
      return;
    }
    isSending.value = true;
    try {
      final res = await ctrl.sendPhoneOtp(phone);
      if (res.success) {
        confirmedPhone.value = phone;
        otpCtrl.clear();
        step.value = 2;
        startCountdown();
        AppSnackbar.success(message: res.message ?? 'OTP bhej diya gaya');
      } else {
        AppSnackbar.error(message: res.message ?? 'OTP bhejne mein error aaya');
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpCtrl.text.trim();
    if (otp.length != 6) {
      AppSnackbar.error(message: '6-digit OTP daalein');
      return;
    }
    isVerifying.value = true;
    try {
      final res = await ctrl.verifyPhoneOtp(otp, confirmedPhone.value);
      if (res.success) {
        countdownTimer?.cancel();
        Get.back();
        AppSnackbar.success(message: res.message ?? 'Phone number update ho gaya');
      } else {
        AppSnackbar.error(message: res.message ?? 'OTP verify nahi hua');
      }
    } finally {
      isVerifying.value = false;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppDimens.lg,
          right: AppDimens.lg,
          top: AppDimens.lg,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppDimens.lg,
        ),
        child: Obx(() => Column(
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
                  step.value == 1 ? 'Change Phone Number' : 'Verify New Number',
                  style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  step.value == 1
                      ? 'Naye number par OTP bhejenge — verify hone ke baad hi ye aapka phone number banega.'
                      : 'OTP bheja gaya +91 ${confirmedPhone.value} par',
                  style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                if (step.value == 1) ...[
                  SitelinkTextField(
                    label: 'New Mobile Number',
                    controller: phoneCtrl,
                    hint: '10-digit number',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    prefix: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Text('+91',
                          style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Send OTP',
                    isLoading: isSending.value,
                    onTap: sendOtp,
                  ),
                ] else ...[
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
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
                    label: 'Verify & Update',
                    isLoading: isVerifying.value,
                    onTap: verifyOtp,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: isSending.value
                            ? null
                            : () {
                                step.value = 1;
                                countdownTimer?.cancel();
                              },
                        child: Text('Change Number',
                            style: KTextStyle.poppins(
                                fs: 12.5, fw: FontWeight.w600, c: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: (isSending.value || resendSeconds.value > 0)
                            ? null
                            : sendOtp,
                        child: Text(
                          resendSeconds.value > 0
                              ? 'Resend in ${resendSeconds.value}s'
                              : 'Resend OTP',
                          style: KTextStyle.poppins(
                              fs: 12.5,
                              fw: FontWeight.w600,
                              c: resendSeconds.value > 0
                                  ? AppColors.textHint
                                  : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            )),
      );
    },
  ).whenComplete(() => countdownTimer?.cancel());
}
