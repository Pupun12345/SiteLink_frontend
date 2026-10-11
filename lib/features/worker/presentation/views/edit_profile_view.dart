import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/theme/searchable_picker.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/worker_feed_controller.dart';
import '../../../../core/theme/experience_cert_list.dart';

// ═══════════════════════════════════════════════════════════════════
//  EDIT PROFILE VIEW — Settings → Edit Profile
// ═══════════════════════════════════════════════════════════════════
class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EditProfileController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'edit_profile_tile'.tr),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _avatarSection(context, ctrl),
                const SizedBox(height: AppDimens.lg),
                _basicInfoCard(context, ctrl),
                const SizedBox(height: AppDimens.md),
                _skillsCard(context, ctrl),
                const SizedBox(height: AppDimens.md),
                _locationCard(ctrl),
                const SizedBox(height: AppDimens.md),
                _workPrefsCard(ctrl),
                const SizedBox(height: AppDimens.md),
                _certificatesCard(context, ctrl),
                const SizedBox(height: AppDimens.xl),
              ],
            ),
          );
        }),
      ),
      // ── Fixed Save button ──────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum:
              const EdgeInsets.fromLTRB(AppDimens.lg, 10, AppDimens.lg, 10),
          child: Obx(() => CustomButton(
                label: 'save_changes_btn'.tr,
                isLoading: ctrl.isSaving.value,
                onTap: ctrl.save,
              )),
        ),
      ),
    );
  }

  // ── Avatar + change photo ───────────────────────────────────────
  Widget _avatarSection(BuildContext context, EditProfileController ctrl) {
    return Center(
      child: Obx(() {
        final newImg = ctrl.newProfileImage.value;
        final serverUrl =
            WorkerFeedController.fullUrl(ctrl.currentProfileImageUrl.value);
        return Stack(children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: newImg != null
                ? Image.file(newImg, fit: BoxFit.cover)
                : serverUrl.isNotEmpty
                    ? Image.network(
                        serverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsAvatar(ctrl.initials),
                      )
                    : _initialsAvatar(ctrl.initials),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _showImageSourceSheet(context, ctrl),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _initialsAvatar(String initials) => Center(
        child: Text(initials,
            style: KTextStyle.poppins(
                fs: 28, fw: FontWeight.bold, c: Colors.white)),
      );

  void _showImageSourceSheet(BuildContext context, EditProfileController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text('camera_label'.tr),
            onTap: () {
              Get.back();
              ctrl.pickProfileImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('gallery_label'.tr),
            onTap: () {
              Get.back();
              ctrl.pickProfileImage(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  // ── Basic info ──────────────────────────────────────────────────
  Widget _basicInfoCard(BuildContext context, EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.person_outline_rounded, 'basic_info_section'.tr),
          const SizedBox(height: 14),
          SitelinkTextField(
            label: AppStrings.FullName,
            controller: ctrl.nameCtrl,
            hint: 'your_name_hint'.tr,
          ),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'nominee_name_label'.tr,
            controller: ctrl.nomineeCtrl,
            hint: 'nominee_name_hint'.tr,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: AppStrings.DateOfBirth,
            controller: ctrl.dobCtrl,
            hint: 'YYYY-MM-DD',
            readOnly: true,
            suffix: const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textSecondary),
            onTap: () => ctrl.pickDob(context),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.Gender,
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => Row(
                children: ['male', 'female', 'other'].map((g) {
                  final selected = ctrl.gender.value == g;
                  final genderLabel = g == 'male'
                      ? AppStrings.Male
                      : (g == 'female' ? AppStrings.Female : AppStrings.Other);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkillChip(
                      label: genderLabel,
                      selected: selected,
                      onTap: () => ctrl.gender.value = g,
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  // ── Skills ──────────────────────────────────────────────────────
  // Primary + Additional dono searchable dropdown se — skills list lambi
  // hoti hai, isliye alphabetically sorted + search wala picker.
  Widget _skillsCard(BuildContext context, EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.construction_rounded, 'skills_section_title'.tr),
          const SizedBox(height: 14),

          // ── Primary skill (single-select) ─────────────────────────
          Text(AppStrings.PrimarySkill,
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => SearchablePickerField(
                hint: 'select_primary_skill_hint'.tr,
                icon: Icons.star_outline_rounded,
                label: ctrl.primarySkillName,
                onTap: () async {
                  final picked = await showSearchablePicker<int>(
                    context: context,
                    title: AppStrings.PrimarySkill,
                    searchHint: 'search_skills_hint'.tr,
                    selected: ctrl.selectedPrimarySkillId.value,
                    options: ctrl.skillOptions,
                  );
                  if (picked != null) ctrl.setPrimarySkill(picked);
                },
              )),
          const SizedBox(height: 14),

          // ── Additional skills (multi-select) ──────────────────────
          Text(AppStrings.AdditionalSkills,
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() {
            final count = ctrl.selectedSecondarySkillIds.length;
            return SearchablePickerField(
              hint: 'select_additional_skills_hint'.tr,
              icon: Icons.build_outlined,
              badgeCount: count,
              label: count == 0
                  ? null
                  : (count == 1
                      ? ctrl.secondarySkillNames.first
                      : 'skills_selected_count'
                          .trParams({'count': '$count'})),
              onTap: () async {
                final picked = await showSearchableMultiPicker<int>(
                  context: context,
                  title: AppStrings.AdditionalSkills,
                  searchHint: 'search_skills_hint'.tr,
                  selected: ctrl.selectedSecondarySkillIds.toList(),
                  // Primary skill additional me na dikhe
                  options: ctrl.skillOptions
                      .where((o) =>
                          o.value != ctrl.selectedPrimarySkillId.value)
                      .toList(),
                );
                if (picked != null) ctrl.setSecondarySkills(picked);
              },
            );
          }),

          // Selected additional skills — chips (tap = remove)
          Obx(() {
            if (ctrl.selectedSecondarySkillIds.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.selectedSecondarySkillIds
                    .map((id) => SkillChip(
                          label: ctrl.skillNameById(id),
                          selected: true,
                          onTap: () => ctrl.toggleSecondarySkill(id),
                        ))
                    .toList(),
              ),
            );
          }),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'other_skill_label'.tr,
            controller: ctrl.otherSkillCtrl,
            hint: 'other_skill_hint_example'.tr,
            onChanged: (_) => ctrl.markSkillsDirty(),
          ),
        ],
      ),
    );
  }

  // ── Location ────────────────────────────────────────────────────
  Widget _locationCard(EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.location_on_outlined, 'work_location_section'.tr),
          const SizedBox(height: 14),
          Text('state_label'.tr, style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => _dropdown<StateModel>(
                value: ctrl.selectedState.value,
                hint: 'select_state_hint'.tr,
                items: ctrl.allStates
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name ?? '')))
                    .toList(),
                onChanged: ctrl.onStateChanged,
              )),
          const SizedBox(height: 12),
          Text('city_label'.tr, style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() {
            if (ctrl.isLoadingCities.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              );
            }
            return _dropdown<CityModel>(
              value: ctrl.selectedCity.value,
              hint: 'select_city_hint'.tr,
              items: ctrl.allCities
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.name ?? '')))
                  .toList(),
              onChanged: ctrl.onCityChanged,
            );
          }),
        ],
      ),
    );
  }

  // ── Work preferences ────────────────────────────────────────────
  Widget _workPrefsCard(EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.work_outline_rounded, AppStrings.WorkPreferences),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Text('total_experience_years_label'.tr,
                  style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
            ),
            Obx(() => CounterWidget(
                  value: ctrl.experienceYears.value ?? 0,
                  min: 0,
                  max: 60,
                  onIncrement: () => ctrl.experienceYears.value =
                      (ctrl.experienceYears.value ?? 0) + 1,
                  onDecrement: () => ctrl.experienceYears.value =
                      ((ctrl.experienceYears.value ?? 0) - 1).clamp(0, 60),
                )),
          ]),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: AppStrings.ExperienceDescription,
            controller: ctrl.expDescCtrl,
            hint: 'experience_desc_hint'.tr,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Text(AppStrings.SalaryType,
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => Row(
                children: ['daily', 'weekly', 'monthly'].map((t) {
                  final selected = ctrl.salaryType.value == t;
                  final salaryLabel = t == 'daily'
                      ? AppStrings.Daily
                      : (t == 'weekly' ? 'weekly_label'.tr : AppStrings.Monthly);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkillChip(
                      label: salaryLabel,
                      selected: selected,
                      onTap: () => ctrl.salaryType.value = t,
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'expected_salary_rupee_label'.tr,
            controller: ctrl.salaryCtrl,
            hint: 'salary_amount_hint'.tr,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Obx(() => Row(children: [
                Expanded(
                  child: Text(AppStrings.WillingToRelocate,
                      style:
                          KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
                ),
                Switch(
                  value: ctrl.willRelocate.value ?? false,
                  onChanged: (v) => ctrl.willRelocate.value = v,
                  activeColor: AppColors.primary,
                ),
              ])),
        ],
      ),
    );
  }

  // ── Experience certificates ─────────────────────────────────────
  // Purane (server par pade) aur naye chune gaye — dono ek hi list me.
  // User purana hata bhi sakta hai; save par backend ko final list
  // jaati hai.
  Widget _certificatesCard(BuildContext context, EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.workspace_premium_outlined,
              'experience_certificate_label'.tr),
          const SizedBox(height: 4),
          Text('cert_upload_hint'.tr,
              style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
          const SizedBox(height: 12),
          Obx(() => ExperienceCertList(
                urls: ctrl.existingCerts
                    .map(WorkerFeedController.fullUrl)
                    .toList(),
                files: ctrl.newCerts,
                isPdf: ctrl.isPdf,
                onRemoveUrl: ctrl.removeExistingCert,
                onRemove: ctrl.removeNewCert,
                onAdd: () => _showCertSheet(context, ctrl),
                canAdd: ctrl.canAddCert,
              )),
        ],
      ),
    );
  }

  void _showCertSheet(BuildContext context, EditProfileController ctrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: Text('camera_label'.tr, style: KTextStyle.poppins(fs: 14)),
              onTap: () {
                Get.back();
                ctrl.pickCert(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title:
                  Text('gallery_label'.tr, style: KTextStyle.poppins(fs: 14)),
              onTap: () {
                Get.back();
                ctrl.pickCert(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
              title: Text('pdf_label'.tr, style: KTextStyle.poppins(fs: 14)),
              onTap: () {
                Get.back();
                ctrl.pickCert(null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Widget _sectionTitle(IconData icon, String title) => Row(children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
      ]);

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: KTextStyle.poppins(fs: 13, c: AppColors.textHint)),
          style: KTextStyle.poppins(fs: 13, c: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
