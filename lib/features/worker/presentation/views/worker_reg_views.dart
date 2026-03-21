import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sitelink/features/worker/presentation/views/worker_home_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/worker_reg_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  STEPPER WIDGET
// ═══════════════════════════════════════════════════════════════════
class _RegStepper extends StatelessWidget {
  final int currentStep;
  const _RegStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Personal\nव्यक्तिगत',
      'Skills\nकौशल',
      'Location\nस्थान'
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg, vertical: AppDimens.md),
      child: Row(
        children: List.generate(3, (i) {
          final isDone = i < currentStep;
          final isActive = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : (isActive
                            ? AppColors.primary
                            : AppColors.divider),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                            : Text(
                          '${i + 1}',
                          style: KTextStyle.poppins(
                            fs: 13,
                            fw: FontWeight.bold,
                            c: isActive
                                ? Colors.white
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: KTextStyle.poppins(
                        fs: 10,
                        c: isActive
                            ? AppColors.primary
                            : (isDone
                            ? AppColors.success
                            : AppColors.textHint),
                        fw: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STEP 1 — PERSONAL INFO
// ═══════════════════════════════════════════════════════════════════
class WorkerReg1View extends StatelessWidget {
  const WorkerReg1View({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerRegController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.createProfile),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _RegStepper(currentStep: 0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StepSectionHeader(
                        title: AppStrings.personalDetails,
                        subtitle: 'Fill in your basic information below',
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // Name
                      SitelinkTextField(
                        label: AppStrings.fullName,
                        hint: 'Enter your full name',
                        controller: ctrl.nameCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // DOB
                      SitelinkTextField(
                        label: AppStrings.dob,
                        hint: 'DD / MM / YYYY',
                        controller: ctrl.dobCtrl,
                        prefixIcon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.datetime,
                        readOnly: true,
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2000),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme:
                                const ColorScheme.light(
                                    primary: AppColors.primary),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null) {
                            ctrl.dobCtrl.text =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          }
                        },
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // Gender
                      Text(
                        AppStrings.gender,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        children:
                        ['Male', 'Female', 'Other'].map((g) {
                          final sel = ctrl.gender.value == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                              ctrl.gender.value = g,
                              child: Container(
                                margin: const EdgeInsets.only(
                                    right: 8),
                                padding:
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.grey.shade100,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.border),
                                ),
                                child: Text(
                                  g,
                                  textAlign: TextAlign.center,
                                  style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w500,
                                    c: sel
                                        ? Colors.white
                                        : AppColors
                                        .textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // City
                      SitelinkTextField(
                        label: AppStrings.city,
                        hint: 'Select your city',
                        controller: ctrl.cityCtrl,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: AppDimens.xl),

                      CustomButton(
                        label: AppStrings.nextBtn,
                        onTap: () =>
                            Get.to(() => const WorkerReg2View()),
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
}

// ═══════════════════════════════════════════════════════════════════
//  STEP 2 — SKILLS & EXPERIENCE
// ═══════════════════════════════════════════════════════════════════
class WorkerReg2View extends StatelessWidget {
  const WorkerReg2View({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WorkerRegController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.createProfile),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _RegStepper(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StepSectionHeader(
                        title: AppStrings.yourSkills,
                        subtitle:
                        'Select the skills you are experienced in',
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // Primary Skill dropdown
                      Text(
                        AppStrings.primarySkill,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Obx(() =>
                          DropdownButtonFormField<String>(
                            value: ctrl.primarySkill.value.isEmpty
                                ? null
                                : ctrl.primarySkill.value,
                            hint: Text(
                              'Select skill',
                              style: KTextStyle.poppins(
                                  fs: 13, c: AppColors.textHint),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                            ),
                            items: AppStrings.allSkills
                                .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: KTextStyle.poppins(
                                        fs: 13))))
                                .toList(),
                            onChanged: (v) =>
                            ctrl.primarySkill.value = v ?? '',
                          )),
                      const SizedBox(height: AppDimens.lg),

                      // Additional skills
                      Text(
                        AppStrings.additionalSkills,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        AppStrings.allSkills.map((s) {
                          final sel =
                          ctrl.additionalSkills.contains(s);
                          return SkillChip(
                            label: s,
                            selected: sel,
                            onTap: () => sel
                                ? ctrl.additionalSkills.remove(s)
                                : ctrl.additionalSkills.add(s),
                          );
                        }).toList(),
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // Experience years
                      Text(
                        AppStrings.experienceYears,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimens.md,
                            horizontal: AppDimens.md),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                              AppDimens.radiusMd),
                          border: Border.all(
                              color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${ctrl.experienceYears.value}',
                                  style: KTextStyle.poppins(
                                      fs: 26,
                                      fw: FontWeight.bold,
                                      c: AppColors.primary),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 3),
                                  child: Text(
                                    'years',
                                    style: KTextStyle.poppins(
                                        fs: 14,
                                        c: AppColors
                                            .textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: ctrl.experienceYears.value
                                  .toDouble(),
                              min: 0,
                              max: 20,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.divider,
                              onChanged: (v) =>
                              ctrl.experienceYears.value =
                                  v.round(),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text('0 yrs',
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.textHint)),
                                Text('20+ yrs',
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.textHint)),
                              ],
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // Experience description
                      Text(
                        AppStrings.expDescription,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          TextFormField(
                            controller: ctrl.expDescCtrl,
                            maxLines: 4,
                            style: KTextStyle.poppins(fs: 13),
                            decoration: InputDecoration(
                              hintText: AppStrings.expPlaceholder,
                              hintStyle: KTextStyle.poppins(
                                  fs: 12, c: AppColors.textHint),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                              contentPadding:
                              const EdgeInsets.fromLTRB(
                                  14, 14, 48, 14),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mic_rounded,
                                  color: AppColors.primary, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.xl),
                      CustomButton(
                        label: AppStrings.nextBtn,
                        onTap: () =>
                            Get.to(() => const WorkerReg3View()),
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
}

// ═══════════════════════════════════════════════════════════════════
//  STEP 3 — LOCATION & SALARY
// ═══════════════════════════════════════════════════════════════════
class WorkerReg3View extends StatelessWidget {
  const WorkerReg3View({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WorkerRegController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.createProfile),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _RegStepper(currentStep: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StepSectionHeader(
                        title: AppStrings.workPreferences,
                        subtitle:
                        'Where do you want to work and how much do you expect?',
                      ),
                      const SizedBox(height: AppDimens.xl),

                      SitelinkTextField(
                        label: AppStrings.workCity,
                        hint: 'e.g. Mumbai, Delhi',
                        controller: ctrl.workCityCtrl,
                        prefixIcon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      SitelinkTextField(
                        label: AppStrings.preferredArea,
                        hint: 'Enter locality',
                        controller: ctrl.preferredAreaCtrl,
                        prefixIcon: Icons.map_outlined,
                        isOptional: true,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // Relocate toggle
                      Text(
                        AppStrings.relocate,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        children: [
                          _ToggleCard(
                            label: AppStrings.yes,
                            selected: ctrl.willRelocate.value,
                            onTap: () =>
                            ctrl.willRelocate.value = true,
                          ),
                          const SizedBox(width: 12),
                          _ToggleCard(
                            label: AppStrings.no,
                            selected: !ctrl.willRelocate.value,
                            onTap: () =>
                            ctrl.willRelocate.value = false,
                          ),
                        ],
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // Salary type
                      Text(
                        AppStrings.salaryType,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => AppSegmentedControl(
                        options: [
                          AppStrings.daily,
                          AppStrings.monthly
                        ],
                        selectedIndex: ctrl.salaryType.value ==
                            'daily'
                            ? 0
                            : 1,
                        onChanged: (i) => ctrl.salaryType.value =
                        i == 0 ? 'daily' : 'monthly',
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // Expected salary
                      Obx(() => SitelinkTextField(
                        label:
                        '${AppStrings.expectedSalary} (₹ per ${ctrl.salaryType.value})',
                        hint: 'Enter amount',
                        controller: ctrl.salaryCtrl,
                        prefixIcon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(height: AppDimens.md),

                      // Info note
                      Container(
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.selectionBg,
                          borderRadius: BorderRadius.circular(
                              AppDimens.radiusMd),
                          border: Border.all(
                              color:
                              AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your profile will be reviewed within 24 hours for the best matches.',
                                style: KTextStyle.poppins(
                                    fs: 12, c: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),

                      CustomButton(
                        label: AppStrings.submitProfile,
                        onTap: () => ctrl.submitStep3(),
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
}

// ── Section header for registration steps ────────────────────────
class _StepSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepSectionHeader(
      {required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KTextStyle.poppins(
              fs: 15,
              fw: FontWeight.w700,
              c: AppColors.primary,
              letterSpacing: 0.3),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style:
          KTextStyle.poppins(fs: 12, c: AppColors.textHint),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleCard(
      {required this.label,
        required this.selected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.06)
                : AppColors.surface,
            borderRadius:
            BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: KTextStyle.poppins(
              fs: 14,
              fw: FontWeight.w600,
              c: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  DOCUMENT UPLOAD VIEW
// ═══════════════════════════════════════════════════════════════════
class DocumentUploadView extends StatelessWidget {
  const DocumentUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<WorkerRegController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.uploadDocs),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoBanner(
                      text:
                      'Upload your ID and work photos for verification / सत्यापन के लिए अपने दस्तावेज़ अपलोड करें',
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── ID Section ─────────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                ),
                                child: const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.govId,
                                style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w600,
                                    letterSpacing: 0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // ID type chips
                          Obx(() => Row(
                            children: AppStrings.idTypes
                                .map((t) {
                              final sel = ctrl
                                  .selectedIdType.value ==
                                  t;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => ctrl
                                      .selectedIdType
                                      .value = t,
                                  child: Container(
                                    margin:
                                    const EdgeInsets.only(
                                        right: 6),
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors
                                          .selectionBg
                                          : AppColors.surface,
                                      borderRadius:
                                      BorderRadius.circular(
                                          AppDimens
                                              .radiusSm),
                                      border: Border.all(
                                          color: sel
                                              ? AppColors
                                              .primary
                                              : AppColors
                                              .border),
                                    ),
                                    child: Text(
                                      t,
                                      textAlign:
                                      TextAlign.center,
                                      style: KTextStyle.poppins(
                                        fs: 11,
                                        fw: sel
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        c: sel
                                            ? AppColors.primary
                                            : AppColors
                                            .textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          )),
                          const SizedBox(height: 16),
                          _UploadBox(
                            onTap: () {
                              /* TODO: image picker */
                            },
                            hasFile: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Work Photos ───────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.selectionBg,
                                  borderRadius:
                                  BorderRadius.circular(
                                      AppDimens.radiusSm),
                                ),
                                child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: AppColors.primary,
                                    size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.workPhotos,
                                style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w600,
                                    letterSpacing: 0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add photos of your past work (optional but recommended)',
                            style: KTextStyle.poppins(
                                fs: 12, c: AppColors.textHint),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: List.generate(
                              3,
                                  (i) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      right: i < 2 ? 8 : 0),
                                  child: _UploadBox(
                                      onTap: () {},
                                      hasFile: false,
                                      compact: true),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                const Icon(
                                    Icons
                                        .add_circle_outline_rounded,
                                    color: AppColors.primary,
                                    size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  'Add more photos',
                                  style: KTextStyle.poppins(
                                      fs: 13,
                                      fw: FontWeight.w500,
                                      c: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.md,
                AppDimens.lg,
                AppDimens.md +
                    MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border:
                Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: CustomButton(
                label: AppStrings.submitVerify,
                onTap: () => ctrl.submitDocuments(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasFile;
  final bool compact;

  const _UploadBox(
      {required this.onTap,
        required this.hasFile,
        this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 90 : 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.03),
          borderRadius:
          BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: hasFile
            ? const Icon(Icons.check_circle_rounded,
            color: AppColors.success, size: 36)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              decoration: BoxDecoration(
                color: AppColors.selectionBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_rounded,
                  color: AppColors.primary,
                  size: compact ? 20 : 24),
            ),
            const SizedBox(height: 6),
            Text(
              compact ? 'Upload' : 'Tap to upload',
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(
                  fs: compact ? 10 : 12,
                  c: AppColors.textSecondary),
            ),
            if (!compact)
              Text(
                'अपलोड करें',
                textAlign: TextAlign.center,
                style: KTextStyle.poppins(
                    fs: 11, c: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE PENDING VIEW
// ═══════════════════════════════════════════════════════════════════
class ProfilePendingView extends StatelessWidget {
  const ProfilePendingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration ──────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: AppColors.selectionBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.primary,
                        size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.profileUnderReview,
                style: KTextStyle.poppins(
                    fs: 20, fw: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.profileUnderReviewHi,
                style: KTextStyle.poppins(
                    fs: 14, c: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ── Steps card ────────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.whatHappensNext,
                      style: KTextStyle.poppins(
                          fs: 13,
                          fw: FontWeight.w600,
                          c: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    _PendingStep(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      label:
                      'Profile submitted / प्रोफाइल जमा हो गई',
                      isDone: true,
                    ),
                    _PendingStep(
                      icon: Icons.sync_rounded,
                      iconColor: AppColors.primary,
                      label:
                      'Admin reviewing documents / दस्तावेज़ जाँचे जा रहे हैं',
                      isCurrent: true,
                    ),
                    _PendingStep(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.textHint,
                      label:
                      "You'll get a notification when approved / मंज़ूरी पर सूचना मिलेगी",
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              CustomButton(
                label: AppStrings.goToHome,
                isOutlined: true,
                onTap: () =>
                    Get.offAll(() => const WorkerHomeView()),
              ),
              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingStep extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _PendingStep({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.isDone = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: KTextStyle.poppins(
                fs: 13,
                c: isDone || isCurrent
                    ? AppColors.textPrimary
                    : AppColors.textHint,
                fw: isCurrent
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}