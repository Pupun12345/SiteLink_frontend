import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/auth_controllers.dart';
import 'auth_views.dart';

// ═══════════════════════════════════════════════════════════════════
//  LANGUAGE SELECTION VIEW
// ═══════════════════════════════════════════════════════════════════
class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LanguageController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Top gradient hero ──────────────────────────────
          Container(
            width: double.infinity,
            height: size.height * 0.38,
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
                  // App icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      color: AppColors.primary,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    AppStrings.appName,
                    style: KTextStyle.poppins(
                      fs: 28,
                      fw: FontWeight.bold,
                      c: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Construction Workforce Platform',
                    style: KTextStyle.poppins(
                      fs: 12,
                      c: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.lg, 28, AppDimens.lg, AppDimens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text(
                      AppStrings.chooseLanguage,
                      style: KTextStyle.poppins(
                          fs: 20, fw: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.chooseLanguageHi,
                      style: KTextStyle.poppins(
                          fs: 14, c: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // ── Hindi card ──────────────────────────
                    Obx(() => _LangCard(
                      symbol: 'अ',
                      title: AppStrings.hindi,
                      subtitle: 'हिंदी',
                      selected:
                      ctrl.selectedLanguage.value == 'hindi',
                      onTap: () => ctrl.select('hindi'),
                    )),
                    const SizedBox(height: AppDimens.md),

                    // ── English card ────────────────────────
                    Obx(() => _LangCard(
                      symbol: 'A',
                      title: AppStrings.english,
                      subtitle: 'अंग्रेज़ी',
                      selected:
                      ctrl.selectedLanguage.value == 'english',
                      onTap: () => ctrl.select('english'),
                    )),

                    const Spacer(),

                    CustomButton(
                      label: AppStrings.continueBtn,
                      onTap: () => Get.off(() => const PhoneView()),
                    ),
                    const SizedBox(height: AppDimens.md),
                    Center(
                      child: Text(
                        'आपकी भाषा, आपकी पसंद 🇮🇳',
                        style: KTextStyle.poppins(
                            fs: 12, c: AppColors.textHint),
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

// ── Language Card ─────────────────────────────────────────────────
class _LangCard extends StatelessWidget {
  final String symbol, title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.symbol,
    required this.title,
    required this.subtitle,
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
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? AppColors.cardShadow : null,
        ),
        child: Row(
          children: [
            // Symbol circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: selected
                    ? AppColors.appBarGradient
                    : null,
                color: selected ? null : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: KTextStyle.poppins(
                    fs: 22,
                    fw: FontWeight.w700,
                    c: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KTextStyle.poppins(
                      fs: 17,
                      fw: FontWeight.w700,
                      c: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: KTextStyle.poppins(
                        fs: 13, c: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}