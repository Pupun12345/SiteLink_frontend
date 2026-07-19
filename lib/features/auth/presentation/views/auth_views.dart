import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
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
                AppDimens.lg, topPad + 16, AppDimens.lg, 36),
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
                // Back button
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child:
                  Icon(headerIcon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: KTextStyle.poppins(
                      fs: 22, fw: FontWeight.bold, c: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: KTextStyle.poppins(
                      fs: 13, c: Colors.white.withOpacity(0.75)),
                ),
              ],
            ),
          ),

          // ── Scrollable content ───────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.lg, 24, AppDimens.lg, AppDimens.lg),
              child: body,
            ),
          ),

          // ── Bottom bar ───────────────────────────────────
          if (bottomBar != null)
            Container(
              padding: EdgeInsets.fromLTRB(
                  AppDimens.lg, 12, AppDimens.lg, 12 + bottomPad),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border:
                Border(top: BorderSide(color: AppColors.divider)),
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
    final ctrl       = Get.find<PhoneController>();
    final googleCtrl = Get.find<GoogleAuthController>();

    return _AuthShell(
      title: 'Login / Register',
      subtitle: 'Enter your mobile number to continue',
      headerIcon: Icons.phone_android_rounded,
      bottomBar: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            TextSpan(
              text: 'Terms',
              style: KTextStyle.poppins(
                  fs: 11, c: AppColors.primary, fw: FontWeight.w600),
            ),
            const TextSpan(text: ' & '),
            TextSpan(
              text: 'Privacy Policy',
              style: KTextStyle.poppins(
                  fs: 11, c: AppColors.primary, fw: FontWeight.w600),
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
                      fs: 12, fw: FontWeight.w500, c: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // +91 prefix
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.selectionBg,
                        borderRadius: const BorderRadius.only(
                          topLeft:    Radius.circular(AppDimens.radiusMd),
                          bottomLeft: Radius.circular(AppDimens.radiusMd),
                        ),
                        border: const Border(
                            right: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(children: [
                        const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text('+91',
                            style: KTextStyle.poppins(
                                fs: 14,
                                fw: FontWeight.w700,
                                c: AppColors.primary)),
                      ]),
                    ),
                    // Number input
                    Expanded(
                      child: TextFormField(
                        controller: ctrl.phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: KTextStyle.poppins(
                            fs: 16, fw: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '00000 00000',
                          hintStyle: KTextStyle.poppins(
                              fs: 14, c: AppColors.textHint),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide:
                            const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight:    Radius.circular(AppDimens.radiusMd),
                              bottomRight: Radius.circular(AppDimens.radiusMd),
                            ),
                            borderSide:
                            const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          filled:    true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 5),
                  Text(
                    'A 6-digit OTP will be sent to this number',
                    style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          // ── Trust badges ──────────────────────────────────
          Row(children: [
            _TrustBadge(icon: Icons.lock_outline_rounded,    label: 'Secure'),
            const SizedBox(width: 10),
            _TrustBadge(icon: Icons.verified_user_outlined,  label: 'Verified'),
            const SizedBox(width: 10),
            _TrustBadge(icon: Icons.flash_on_rounded,        label: 'Instant OTP'),
          ]),
          const SizedBox(height: AppDimens.xl),

          // ── Send OTP button ───────────────────────────────
          Obx(() => CustomButton(
            label:     AppStrings.SendOTP,
            onTap:     ctrl.sendOtp,
            isLoading: ctrl.isLoading.value,
          )),
          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────
          Row(children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR',
                style: KTextStyle.poppins(
                    fs: 12,
                    c: AppColors.textHint,
                    fw: FontWeight.w500),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ]),
          const SizedBox(height: 20),

          // ── Google Sign-In button ─────────────────────────
          Obx(() => _GoogleSignInButton(
            isLoading: googleCtrl.isLoading.value,
            onTap:     googleCtrl.signInWithGoogle,
          )),
        ],
      ),
    );
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final bool         isLoading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 'G' logo
            Container(
              width:  24,
              height: 24,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.network(
                'https://www.google.com/favicon.ico',
                width:  22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata_rounded,
                  color:  Colors.red,
                  size:   26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
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
                  fs: 10, fw: FontWeight.w500, c: AppColors.textSecondary),
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
      subtitle: 'Enter the 6-digit code sent to +91 $phone',
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
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.selectionBg,
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '+91 $phone',
                        style: KTextStyle.poppins(
                            fs: 14,
                            fw: FontWeight.w600,
                            c: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'Change',
                          style: KTextStyle.poppins(
                              fs: 12,
                              fw: FontWeight.w500,
                              c: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OTP boxes
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                        (i) => _OtpBox(
                      controller: ctrl.otpCtrls[i],
                      focusNode: ctrl.focusNodes[i],
                      onChanged: (v) =>
                          ctrl.onOtpChanged(v, i),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend
                Obx(() => ctrl.secondsLeft.value > 0
                    ? Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 15,
                        color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Resend in ${ctrl.secondsLeft.value.toString().padLeft(2, '0')}s',
                      style: KTextStyle.poppins(
                          fs: 13, c: AppColors.textHint),
                    ),
                  ],
                )
                    : GestureDetector(
                  onTap: ctrl.resend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.selectionBg,
                      borderRadius: BorderRadius.circular(
                          AppDimens.radiusMax),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                            Icons.refresh_rounded,
                            size: 15,
                            color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          AppStrings.ResendOTP,
                          style: KTextStyle.poppins(
                              fs: 13,
                              fw: FontWeight.w600,
                              c: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.lg),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: AppColors.selectionBg,
              borderRadius:
              BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OTP +91 $phone पर भेजा गया है। कोड 10 मिनट में expire होगा।',
                    style: KTextStyle.poppins(
                        fs: 12, c: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.xl),

          Obx(() => CustomButton(
            label: AppStrings.VerifyContinue,
            onTap: ctrl.verify,
            isLoading: ctrl.isLoading.value,
          )),
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
            fs: 22, fw: FontWeight.bold, c: AppColors.textPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: controller.text.isNotEmpty
              ? AppColors.selectionBg
              : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(
                color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(AppDimens.radiusMd),
            borderSide: const BorderSide(
                color: AppColors.border, width: 1.5),
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
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.waving_hand_rounded,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.IAm,
                    style: KTextStyle.poppins(
                        fs: 24, fw: FontWeight.bold, c: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your role to get started',
                    style: KTextStyle.poppins(
                        fs: 13,
                        c: Colors.white.withOpacity(0.75)),
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
                    AppDimens.lg, 28, AppDimens.lg, AppDimens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.SelectYourRoleToContinue,
                      style: KTextStyle.poppins(
                          fs: 15, fw: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppStrings.SelectRole,
                      style: KTextStyle.poppins(
                          fs: 13, c: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Vendor
                    // Vendor
                    Obx(() => _RoleCard(
                      icon: Icons.corporate_fare_rounded,
                      title: AppStrings.Vendor,
                      subtitleEn: AppStrings.IWantToHireWorkers,
                      subtitleHi: AppStrings.HireWorkers,
                      tag: 'Contractor / ठेकेदार',
                      selected: ctrl.selectedRole.value == 'vendor',
                      onTap: () => ctrl.select('vendor'),
                    )),
                    const SizedBox(height: AppDimens.md),

// Worker
                    Obx(() => _RoleCard(
                      icon: Icons.engineering_rounded,
                      title: AppStrings.Worker,
                      subtitleEn: AppStrings.IAmLookingForWork,
                      subtitleHi: AppStrings.LookingForWork,

                      // Updated Professional Tag
                      tag: 'Employee / कर्मचारी',

                      selected: ctrl.selectedRole.value == 'worker',
                      onTap: () => ctrl.select('worker'),
                    )),
                    const Spacer(),

                    Obx(() => CustomButton(
                      label: AppStrings.Continue,
                      onTap: ctrl.selectedRole.isNotEmpty
                          ? ctrl.proceed
                          : null,
                    )),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'You can change your role later from settings',
                        style: KTextStyle.poppins(
                            fs: 11, c: AppColors.textHint),
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
          borderRadius:
          BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color:
            selected ? AppColors.primary : AppColors.border,
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
                gradient: selected
                    ? AppColors.appBarGradient
                    : null,
                color: selected ? null : Colors.grey.shade100,
                borderRadius:
                BorderRadius.circular(AppDimens.radiusLg),
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
                  Row(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.12)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(
                              AppDimens.radiusMax),
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
                        fs: 12, c: AppColors.textSecondary),
                  ),
                  Text(
                    subtitleHi,
                    style: KTextStyle.poppins(
                        fs: 12, c: AppColors.textHint),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected
                  ? AppColors.primary
                  : AppColors.textHint,
              size: selected ? 24 : 22,
            ),
          ],
        ),
      ),
    );
  }
}
