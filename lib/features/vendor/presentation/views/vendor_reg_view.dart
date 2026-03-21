import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/vendor_reg_controller.dart';
import 'vendor_home_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR REGISTRATION VIEW
// ═══════════════════════════════════════════════════════════════════
class VendorRegistrationView extends StatelessWidget {
  const VendorRegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorRegController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.companyProfile),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          gradient: AppColors.appBarGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.companyInfo,
                        style: KTextStyle.poppins(
                            fs: 16, fw: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.companyInfoHi,
                        style: KTextStyle.poppins(
                            fs: 13, c: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppDimens.xl),

                // ── Company Details Section ─────────────────
                _FieldSectionLabel(
                  icon: Icons.business_rounded,
                  title: 'Company Details',
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.companyName,
                  hint: 'Enter company name',
                  controller: ctrl.companyNameCtrl,
                  prefixIcon: Icons.business_rounded,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.contactPerson,
                  hint: 'Enter name',
                  controller: ctrl.contactPersonCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.designation,
                  hint: 'e.g., Manager, Owner, Site Engineer',
                  controller: ctrl.designationCtrl,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Location Section ────────────────────────
                _FieldSectionLabel(
                  icon: Icons.location_on_outlined,
                  title: 'Location & Area',
                ),
                const SizedBox(height: AppDimens.md),

                Text(
                  AppStrings.city,
                  style: KTextStyle.poppins(
                      fs: 12,
                      fw: FontWeight.w500,
                      c: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  hint: Text(
                    'Select city',
                    style: KTextStyle.poppins(
                        fs: 13, c: AppColors.textHint),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 22),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(AppDimens.radiusMd),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                  items: [
                    'Jaipur',
                    'Delhi',
                    'Mumbai',
                    'Pune',
                    'Ahmedabad',
                    'Surat',
                    'Lucknow',
                    'Bhopal'
                  ]
                      .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: KTextStyle.poppins(fs: 13))))
                      .toList(),
                  onChanged: (v) => ctrl.city.value = v ?? '',
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.workArea,
                  hint: 'Areas where you hire',
                  controller: ctrl.workAreaCtrl,
                  isOptional: true,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Optional Section ────────────────────────
                _FieldSectionLabel(
                  icon: Icons.receipt_long_rounded,
                  title: 'Tax Details (Optional)',
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.gst,
                  hint: 'Enter GSTIN',
                  controller: ctrl.gstCtrl,
                  isOptional: true,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Info Note ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.selectionBg,
                    borderRadius:
                    BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.activationNote,
                              style: KTextStyle.poppins(
                                  fs: 12,
                                  fw: FontWeight.w500,
                                  c: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Padding(
                        padding: const EdgeInsets.only(left: 21),
                        child: Text(
                          AppStrings.activationNoteHi,
                          style: KTextStyle.poppins(
                              fs: 11, c: AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Submit ──────────────────────────────────
                Obx(() => CustomButton(
                  label: AppStrings.createAccount,
                  onTap: ctrl.submit,
                  isLoading: ctrl.isLoading.value,
                  leading: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20),
                )),
                const SizedBox(height: AppDimens.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Field Section Label ───────────────────────────────────────────
class _FieldSectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  const _FieldSectionLabel(
      {required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: KTextStyle.poppins(
              fs: 13, fw: FontWeight.w600, c: AppColors.primary),
        ),
      ],
    );
  }
}