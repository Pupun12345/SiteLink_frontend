import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/worker_feed_controller.dart';

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
      appBar: GradientAppBar(title: 'Edit Profile'),
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
                _skillsCard(ctrl),
                const SizedBox(height: AppDimens.md),
                _locationCard(ctrl),
                const SizedBox(height: AppDimens.md),
                _workPrefsCard(ctrl),
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
                label: 'Save Changes',
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
            title: const Text('Camera'),
            onTap: () {
              Get.back();
              ctrl.pickProfileImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
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
          _sectionTitle(Icons.person_outline_rounded, 'Basic Info'),
          const SizedBox(height: 14),
          SitelinkTextField(
            label: 'Full Name',
            controller: ctrl.nameCtrl,
            hint: 'Your name',
          ),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'Date of Birth',
            controller: ctrl.dobCtrl,
            hint: 'YYYY-MM-DD',
            readOnly: true,
            suffix: const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textSecondary),
            onTap: () => ctrl.pickDob(context),
          ),
          const SizedBox(height: 12),
          Text('Gender',
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => Row(
                children: ['male', 'female', 'other'].map((g) {
                  final selected = ctrl.gender.value == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkillChip(
                      label: g[0].toUpperCase() + g.substring(1),
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
  Widget _skillsCard(EditProfileController ctrl) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.construction_rounded, 'Skills'),
          const SizedBox(height: 14),
          Text('Primary Skill',
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => _dropdown<int>(
                value: ctrl.selectedPrimarySkillId.value,
                hint: 'Select primary skill',
                items: ctrl.allSkills
                    .where((s) => s.skillId != null)
                    .map((s) => DropdownMenuItem(
                        value: s.skillId, child: Text(s.name ?? '')))
                    .toList(),
                onChanged: ctrl.setPrimarySkill,
              )),
          const SizedBox(height: 14),
          Text('Additional Skills',
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ctrl.allSkills
                    .where((s) =>
                        s.skillId != null &&
                        s.skillId != ctrl.selectedPrimarySkillId.value)
                    .map((s) => SkillChip(
                          label: s.name ?? '',
                          selected: ctrl.selectedSecondarySkillIds
                              .contains(s.skillId),
                          onTap: () => ctrl.toggleSecondarySkill(s.skillId!),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'Other Skill',
            controller: ctrl.otherSkillCtrl,
            hint: 'e.g. Tilling',
            isOptional: true,
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
          _sectionTitle(Icons.location_on_outlined, 'Work Location'),
          const SizedBox(height: 14),
          Text('State', style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => _dropdown<StateModel>(
                value: ctrl.selectedState.value,
                hint: 'Select state',
                items: ctrl.allStates
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name ?? '')))
                    .toList(),
                onChanged: ctrl.onStateChanged,
              )),
          const SizedBox(height: 12),
          Text('City', style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
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
              hint: 'Select city',
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
          _sectionTitle(Icons.work_outline_rounded, 'Work Preferences'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Text('Total Experience (years)',
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
            label: 'Experience Description',
            controller: ctrl.expDescCtrl,
            hint: 'Apne kaam ke baare me likhein (optional)',
            maxLines: 3,
            isOptional: true,
          ),
          const SizedBox(height: 12),
          Text('Salary Type',
              style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
          const SizedBox(height: 8),
          Obx(() => Row(
                children: ['daily', 'weekly', 'monthly'].map((t) {
                  final selected = ctrl.salaryType.value == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkillChip(
                      label: t[0].toUpperCase() + t.substring(1),
                      selected: selected,
                      onTap: () => ctrl.salaryType.value = t,
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 12),
          SitelinkTextField(
            label: 'Expected Salary (₹)',
            controller: ctrl.salaryCtrl,
            hint: 'e.g. 15000',
            keyboardType: TextInputType.number,
            isOptional: true,
          ),
          const SizedBox(height: 12),
          Obx(() => Row(children: [
                Expanded(
                  child: Text('Willing to Relocate',
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
