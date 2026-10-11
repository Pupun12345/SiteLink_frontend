import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../app/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../shared/presentation/views/help_support_views.dart';
import '../controllers/auth_controllers.dart';

// ═══════════════════════════════════════════════════════════════════
//  SHARED — Auth Screen Shell (gradient top + card body)
// ═══════════════════════════════════════════════════════════════════
class _AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData headerIcon;
  final Widget body;
  final Widget? bottomBar;

  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.headerIcon,
    required this.body,
    this.bottomBar,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppDimens.lg,
              topPad + 16,
              AppDimens.lg,
              36,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.appBarGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button — sirf tab jab wapas jaane ke liye kuch ho.
                // Login screen par language se `Get.offNamed` se aate hain
                // (stack replace ho jaata hai), isliye wahan back ka koi
                // matlab nahi tha — ab apne aap chhup jaata hai. OTP screen
                // par `Get.toNamed` se aate hain, wahan dikhega (number
                // badalne ke liye kaam ka hai).
                if (Navigator.canPop(context)) ...[
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(headerIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: KTextStyle.poppins(
                    fs: 22,
                    fw: FontWeight.bold,
                    c: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: KTextStyle.poppins(
                    fs: 13,
                    c: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.lg,
                24,
                AppDimens.lg,
                AppDimens.lg,
              ),
              child: body,
            ),
          ),

          // ── Bottom bar ───────────────────────────────────
          if (bottomBar != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg,
                12,
                AppDimens.lg,
                12 + bottomPad,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: bottomBar,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PHONE VIEW
// ═══════════════════════════════════════════════════════════════════
// lib/features/auth/presentation/views/auth_views.dart
// Sirf PhoneView update — baaki sab same rehta hai
// PhoneView ke body mein yeh add karo existing CustomButton ke neeche:

// ─────────────────────────────────────────────────────────────────
// Yeh poora PhoneView replace karo apne auth_views.dart mein
// ─────────────────────────────────────────────────────────────────

class PhoneView extends StatelessWidget {
  const PhoneView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PhoneController>();
    final googleCtrl = Get.find<GoogleAuthController>();

    return _AuthShell(
      title: 'login_register_title'.tr,
      subtitle: 'enter_mobile_continue_subtitle'.tr,
      headerIcon: Icons.phone_android_rounded,
      // Terms/Privacy ab actually tappable hain — pehle sirf link jaise
      // dikhte the par tap par kuch nahi hota tha.
      bottomBar: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
          children: [
            TextSpan(text: '${'by_continuing_you_agree'.tr} '),
            TextSpan(
              text: AppStrings.Terms,
              style: KTextStyle.poppins(
                fs: 11,
                c: AppColors.primary,
                fw: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Get.to(
                  () => PolicyView(
                    title: AppStrings.Terms,
                    content: '',
                    policyType: 'TERMS_AND_CONDITIONS',
                  ),
                ),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: AppStrings.PrivacyPolicy,
              style: KTextStyle.poppins(
                fs: 11,
                c: AppColors.primary,
                fw: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Get.to(
                  () => PolicyView(
                    title: AppStrings.PrivacyPolicy,
                    content: '',
                    policyType: 'PRIVACY_POLICY',
                  ),
                ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Phone input card ──────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.MobileNumber,
                  style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w500,
                    c: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // +91 prefix
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.selectionBg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusMd),
                          bottomLeft: Radius.circular(AppDimens.radiusMd),
                        ),
                        border: const Border(
                          right: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+91',
                            style: KTextStyle.poppins(
                              fs: 14,
                              fw: FontWeight.w700,
                              c: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Number input
                    Expanded(
                      child: TextFormField(
                        controller: ctrl.phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        // Keyboard ke "done" se seedha OTP chala jaaye
                        onFieldSubmitted: (_) => ctrl.sendOtp(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '00000 00000',
                          hintStyle: KTextStyle.poppins(
                            fs: 14,
                            c: AppColors.textHint,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'otp_will_be_sent_note'.tr,
                      style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          // ── Trust badges ──────────────────────────────────
          Row(
            children: [
              _TrustBadge(
                icon: Icons.lock_outline_rounded,
                label: 'secure_label'.tr,
              ),
              const SizedBox(width: 10),
              _TrustBadge(
                icon: Icons.verified_user_outlined,
                label: 'verified'.tr,
              ),
              const SizedBox(width: 10),
              _TrustBadge(
                icon: Icons.flash_on_rounded,
                label: 'instant_otp_label'.tr,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xl),

          // ── Send OTP button ───────────────────────────────
          Obx(
            () => CustomButton(
              label: AppStrings.SendOTP,
              onTap: ctrl.sendOtp,
              isLoading: ctrl.isLoading.value,
            ),
          ),
          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'or_divider_label'.tr,
                  style: KTextStyle.poppins(
                    fs: 12,
                    c: AppColors.textHint,
                    fw: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Google Sign-In button ─────────────────────────
          Obx(
            () => _GoogleSignInButton(
              isLoading: googleCtrl.isLoading.value,
              onTap: googleCtrl.signInWithGoogle,
            ),
          ),
        ],
      ),
    );
  }
}

// Official Google "G" — inline rakha hai taaki button offline bhi sahi
// render ho (pehle ye google.com/favicon.ico se network par load hota tha:
// internet chahiye tha, flicker hota tha, aur fail hone par ek galat sa
// red icon dikhta tha).
const String _kGoogleGSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
<path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

// ── Google Sign-In Button ─────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google 'G' logo — inline SVG, koi network call nahi
                  SvgPicture.string(_kGoogleGSvg, width: 20, height: 20),
                  const SizedBox(width: 12),
                  Text(
                    'continue_with_google_btn'.tr,
                    style: KTextStyle.poppins(
                      fs: 15,
                      fw: FontWeight.w600,
                      c: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Trust Badge ───────────────────────────────────────────────────
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: KTextStyle.poppins(
                fs: 10,
                fw: FontWeight.w500,
                c: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OTP VIEW
// ═══════════════════════════════════════════════════════════════════
class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<OtpController>();
    final phone = ctrl.phone;

    return _AuthShell(
      title: AppStrings.VerifyOTP,
      subtitle: 'enter_code_sent_to'.trParams({'phone': phone}),
      headerIcon: Icons.shield_rounded,
      body: Column(
        children: [
          // ── OTP card ───────────────────────────────────
          AppCard(
            child: Column(
              children: [
                // Phone display row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.selectionBg,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+91 $phone',
                        style: KTextStyle.poppins(
                          fs: 14,
                          fw: FontWeight.w600,
                          c: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'change_label'.tr,
                          style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    AppConfig.otpLength,
                    (i) => _OtpBox(
                      controller: ctrl.otpCtrls[i],
                      focusNode: ctrl.focusNodes[i],
                      onChanged: (v) => ctrl.onOtpChanged(v, i),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend
                Obx(
                  () => ctrl.secondsLeft.value > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 15,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'resend_in_seconds'.trParams({
                                'seconds': ctrl.secondsLeft.value
                                    .toString()
                                    .padLeft(2, '0'),
                              }),
                              style: KTextStyle.poppins(
                                fs: 13,
                                c: AppColors.textHint,
                              ),
                            ),
                          ],
                        )
                      : GestureDetector(
                          onTap: ctrl.resend,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.selectionBg,
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMax,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  AppStrings.ResendOTP,
                                  style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w600,
                                    c: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.selectionBg,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'otp_sent_expiry_note'.trParams({'phone': phone}),
                    style: KTextStyle.poppins(fs: 12, c: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.xl),

          Obx(
            () => CustomButton(
              label: AppStrings.VerifyContinue,
              onTap: ctrl.verify,
              isLoading: ctrl.isLoading.value,
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Box ───────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: KTextStyle.poppins(
          fs: 22,
          fw: FontWeight.bold,
          c: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: controller.text.isNotEmpty
              ? AppColors.selectionBg
              : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROLE SELECTION VIEW
// ═══════════════════════════════════════════════════════════════════
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<RoleController>();
    final size = MediaQuery.of(context).size;

    // OTP verify ho chuka hai par registration adhoora hai — is screen se
    // "back" ka matlab hai signup chhod ke doosre number se shuru karna,
    // isliye hardware back bhi wahi confirm flow chalata hai.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmChangeNumber(ctrl);
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Column(
          children: [
            // ── Gradient header ──────────────────────────────
            Container(
              width: double.infinity,
              height: size.height * 0.30,
              decoration: const BoxDecoration(
                gradient: AppColors.appBarGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                bottom: false,
                // expand — warna non-positioned Column shrink-wrap ho kar
                // top-left chala jaata hai aur header ka centering toot jaata hai
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.waving_hand_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.IAm,
                          style: KTextStyle.poppins(
                            fs: 24,
                            fw: FontWeight.bold,
                            c: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'choose_role_get_started_subtitle'.tr,
                          style: KTextStyle.poppins(
                            fs: 13,
                            c: Colors.white.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                    // Back — galat number pe OTP kar liya to yahin se wapas.
                    // Baaki auth screens ke back button jaisa hi look.
                    Positioned(
                      top: 8,
                      left: AppDimens.lg,
                      child: Obx(
                        () => GestureDetector(
                          onTap: ctrl.isLeaving.value
                              ? null
                              : () => _confirmChangeNumber(ctrl),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Role cards ───────────────────────────────────
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.lg,
                    28,
                    AppDimens.lg,
                    AppDimens.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.SelectYourRoleToContinue,
                        style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.SelectRole,
                        style: KTextStyle.poppins(
                          fs: 13,
                          c: AppColors.textSecondary,
                        ),
                      ),

                      // Kis account se aage badh rahe hain — galat number ho
                      // to yahin se badal sakte hain (back icon ka hi shortcut)
                      if (ctrl.loggedInAs.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                ctrl.loggedInAs,
                                style: KTextStyle.poppins(
                                  fs: 12.5,
                                  fw: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(
                              () => GestureDetector(
                                onTap: ctrl.isLeaving.value
                                    ? null
                                    : () => _confirmChangeNumber(ctrl),
                                child: Text(
                                  'change_label'.tr,
                                  style: KTextStyle.poppins(
                                    fs: 12.5,
                                    fw: FontWeight.w700,
                                    c: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Vendor
                      // Vendor
                      Obx(
                        () => _RoleCard(
                          icon: Icons.corporate_fare_rounded,
                          title: AppStrings.Vendor,
                          subtitleEn: AppStrings.IWantToHireWorkers,
                          subtitleHi: AppStrings.HireWorkers,
                          tag: 'Contractor / ठेकेदार',
                          selected: ctrl.selectedRole.value == 'vendor',
                          onTap: () => ctrl.select('vendor'),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),

                      // Worker
                      Obx(
                        () => _RoleCard(
                          icon: Icons.engineering_rounded,
                          title: AppStrings.Worker,
                          subtitleEn: AppStrings.IAmLookingForWork,
                          subtitleHi: AppStrings.LookingForWork,

                          // Cross-language hint. Title (`AppStrings.Worker`)
                          // pehle se "Employee / Worker" deta hai, isliye
                          // tag me doosri bhasha aati hai — warna dono me
                          // wahi text repeat hota aur Row overflow karti.
                          tag: 'role_worker_tag'.tr,

                          selected: ctrl.selectedRole.value == 'worker',
                          onTap: () => ctrl.select('worker'),
                        ),
                      ),
                      const Spacer(),

                      Obx(
                        () => CustomButton(
                          label: AppStrings.Continue,
                          onTap: ctrl.selectedRole.isNotEmpty
                              ? ctrl.proceed
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'change_role_later_note'.tr,
                          style: KTextStyle.poppins(
                            fs: 11,
                            c: AppColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back / "Change" dono yahi chalate hain. Confirm isliye zaroori hai
  /// ki ye sirf navigation nahi — session clear hota hai aur naye number
  /// pe dobara OTP verify karna padta hai.
  void _confirmChangeNumber(RoleController ctrl) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'change_number_title'.tr,
          style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600),
        ),
        content: Text(
          'change_number_message'.tr,
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
          TextButton(
            onPressed: () {
              Get.back(); // dialog band karo
              ctrl.changeNumber();
            },
            child: Text(
              'change_number_btn'.tr,
              style: KTextStyle.poppins(
                fs: 13,
                fw: FontWeight.w600,
                c: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitleEn, subtitleHi, tag;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitleEn,
    required this.subtitleHi,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectionBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppColors.cardShadow : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.appBarGradient : null,
                color: selected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap, Row nahi: tag teen hisson ka hai ("Employee /
                  // Worker / कर्मचारी") aur title ke saath ek line me nahi
                  // aata. Wrap use ellipsize karne ke bajaye agli line par
                  // le jaata hai — chhote tag (Contractor) waise hi ek
                  // line me rehte hain.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: KTextStyle.poppins(
                          fs: 16,
                          fw: FontWeight.w700,
                          c: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMax,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: KTextStyle.poppins(
                            fs: 9,
                            fw: FontWeight.w600,
                            c: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitleEn,
                    style: KTextStyle.poppins(
                      fs: 12,
                      c: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    subtitleHi,
                    style: KTextStyle.poppins(fs: 12, c: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? AppColors.primary : AppColors.textHint,
              size: selected ? 24 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
