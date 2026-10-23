import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/dictation_mic_button.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/worker_reg_controller.dart';
import '../../../../core/models/skill_models.dart';
import '../../../../core/theme/experience_cert_list.dart';
import 'dart:io';
import 'dart:async';

// ═══════════════════════════════════════════════════════════════════
//  STEPPER WIDGET
// ═══════════════════════════════════════════════════════════════════
// ── Profile photo picker (registration Step 1) ──────────────────────
// Circular avatar + camera badge. Photo na ho to dashed-feel placeholder
// aur neeche hint, taaki worker samjhe ki chehre ki photo chahiye — na ki
// kaam ki photo (wo alag "Work Samples" me maangi jaati hai).
class _ProfilePhotoPicker extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ProfilePhotoPicker({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final has = file != null;
    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.selectionBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: has ? AppColors.primary : AppColors.border,
                    width: has ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: has
                    ? Image.file(file!, fit: BoxFit.cover)
                    : const Icon(Icons.person_outline_rounded,
                        size: 40, color: AppColors.textHint),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: Icon(
                    has ? Icons.edit_rounded : Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (has)
          TextButton(
            onPressed: onRemove,
            child: Text('remove_label'.tr,
                style: KTextStyle.poppins(fs: 12, c: AppColors.error)),
          )
        else
          Text(
            'add_profile_photo_hint'.tr,
            textAlign: TextAlign.center,
            style: KTextStyle.poppins(fs: 11.5, c: AppColors.textHint),
          ),
      ],
    );
  }
}

class _RegStepper extends StatelessWidget {
  final int currentStep;
  const _RegStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final labels = [
      'reg_step_personal'.tr,
      'reg_step_skills'.tr,
      'reg_step_location'.tr,
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
                        fw: isActive ? FontWeight.w600 : FontWeight.normal,
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
                        color: isDone ? AppColors.success : AppColors.divider,
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
      appBar: GradientAppBar(title: AppStrings.CreateProfile),
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
                        title: AppStrings.PersonalDetails,
                        subtitle: 'reg1_subtitle'.tr,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ── Profile photo ─────────────────────────────
                      // Registration me hi maangte hain: baad me Edit
                      // Profile se daalna zyadatar kabhi hota nahi, aur
                      // vendor ko applicant list me chehra dikhna chahiye.
                      Center(
                        child: Obx(() => _ProfilePhotoPicker(
                              file: ctrl.profilePhoto.value,
                              onPick: () => ctrl.showImageSourceSheet(
                                context: context,
                                onSelect: ctrl.pickProfilePhoto,
                              ),
                              onRemove: ctrl.removeProfilePhoto,
                            )),
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // ── Name ──────────────────────────────────────
                      SitelinkTextField(
                        label: AppStrings.FullName,
                        hint: 'full_name_hint'.tr,
                        controller: ctrl.nameCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ── Nominee ───────────────────────────────────
                      SitelinkTextField(
                        label: 'nominee_name_label'.tr,
                        hint: 'nominee_name_hint'.tr,
                        controller: ctrl.nomineeCtrl,
                        prefixIcon: Icons.family_restroom_rounded,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 100,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'nominee_name_helper'.tr,
                        style: KTextStyle.poppins(
                            fs: 11, c: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ── Date of Birth ─────────────────────────────
                      SitelinkTextField(
                        label: AppStrings.DateOfBirth,
                        hint: 'YYYY-MM-DD',
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
                                colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary),
                              ),
                              child: child!,
                            ),
                          );
                          if (d != null) {
                            ctrl.dobCtrl.text =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ── Gender ────────────────────────────────────
                      Text(
                        AppStrings.Gender,
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
                          final genderLabel = g == 'Male'
                              ? AppStrings.Male
                              : (g == 'Female'
                                  ? AppStrings.Female
                                  : AppStrings.Other);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => ctrl.gender.value = g,
                              child: Container(
                                margin:
                                const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusSm),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : AppColors.border),
                                ),
                                child: Text(
                                  genderLabel,
                                  textAlign: TextAlign.center,
                                  style: KTextStyle.poppins(
                                    fs: 13,
                                    fw: FontWeight.w500,
                                    c: sel
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),

                      const SizedBox(height: AppDimens.xl),

                      CustomButton(
                        label: AppStrings.Next,
                        onTap: ctrl.submitStep1,
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
      appBar: GradientAppBar(title: AppStrings.CreateProfile),
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
                        title: AppStrings.SkillsExperience,
                        subtitle: 'reg2_subtitle'.tr,
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // ── Primary Skill ──────────────────────────────
                      Text(
                        AppStrings.PrimarySkill,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const MultiSelectSkillField(singleSelect: true),
                      const SizedBox(height: AppDimens.lg),

                      // ── Additional Skills (Multi-Select Dropdown) ──
                      Text(
                        AppStrings.AdditionalSkills,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const MultiSelectSkillField(),

                      // ── Other skill field ──────────────────────────
                      Obx(() {
                        SkillModel? otherSkillEntry;
                        try {
                          otherSkillEntry = ctrl.allSkills
                              .firstWhere((s) => s.name == 'Other');
                        } catch (_) {
                          otherSkillEntry = null;
                        }
                        final showOther = (otherSkillEntry != null &&
                            otherSkillEntry.skillId != null &&
                            ctrl.selectedSecondarySkillIds
                                .contains(otherSkillEntry.skillId)) ||
                            ctrl.otherSkillCtrl.text.isNotEmpty;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: showOther
                              ? Column(
                            key: const ValueKey('otherSkillField'),
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppDimens.lg),
                              Text('other_skill_label'.tr,
                                  style: KTextStyle.poppins(
                                      fs: 12,
                                      fw: FontWeight.w500,
                                      c: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              SitelinkTextField(
                                label:
                                'describe_other_skill'.tr,
                                hint: 'enter_custom_skill_hint'.tr,
                                controller: ctrl.otherSkillCtrl,
                                prefixIcon: Icons.edit_outlined,
                              ),
                            ],
                          )
                              : const SizedBox.shrink(),
                        );
                      }),

                      const SizedBox(height: AppDimens.lg),

                      // ── Experience Years ───────────────────────────
                      Text(
                        AppStrings.TotalExperience,
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
                          border:
                          Border.all(color: AppColors.border),
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
                                  child: Text('years_label'.tr,
                                      style: KTextStyle.poppins(
                                          fs: 14,
                                          c: AppColors
                                              .textSecondary)),
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
                                Text('zero_yrs'.tr,
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.textHint)),
                                Text('twenty_plus_yrs'.tr,
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.textHint)),
                              ],
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // ── Experience Description ─────────────────────
                      Text(
                        AppStrings.ExperienceDescription,
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
                              hintText: AppStrings.DescribeYourPastWork,
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
                              contentPadding: const EdgeInsets.fromLTRB(
                                  14, 14, 48, 14),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: DictationMicButton(
                                controller: ctrl.expDescCtrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.xl),

                      CustomButton(
                        label: AppStrings.Next,
                        onTap: ctrl.goToStep3,
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
//  MULTI SELECT SKILL FIELD
// ═══════════════════════════════════════════════════════════════════
class MultiSelectSkillField extends StatefulWidget {
  /// `true` = Primary Skill (ek hi chun sakte hain), `false` = Additional
  /// Skills (multi). Design dono ka bilkul same hai — isiliye do alag
  /// widgets banane ke bajaye yahi widget dono modes handle karta hai,
  /// warna ek jagah style badalne par doosri jagah chhoot jaati.
  final bool singleSelect;

  const MultiSelectSkillField({super.key, this.singleSelect = false});

  @override
  State<MultiSelectSkillField> createState() => _MultiSelectSkillFieldState();
}

class _MultiSelectSkillFieldState extends State<MultiSelectSkillField>
    with SingleTickerProviderStateMixin {
  final ctrl = Get.find<WorkerRegController>();
  final _searchCtrl = TextEditingController();
  final _overlayKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  final _searchQuery = ''.obs;

  /// Abhi kaunse ids selected hain — dono modes ke liye ek hi shape.
  List<int> get _selectedIds => widget.singleSelect
      ? (ctrl.selectedPrimarySkillId.value == null
          ? const []
          : [ctrl.selectedPrimarySkillId.value!])
      : ctrl.selectedSecondarySkillIds;

  void _onPick(int id) {
    if (!widget.singleSelect) {
      ctrl.toggleSecondarySkillId(id);
      return;
    }
    // Single-select: dobara wahi tap = deselect, warna replace. Chunne ke
    // baad panel band — multi ki tarah khula rakhne ka matlab nahi.
    ctrl.selectedPrimarySkillId.value =
        ctrl.selectedPrimarySkillId.value == id ? null : id;
    _closeDropdown();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    _isOpen ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    _searchCtrl.clear();
    _searchQuery.value = '';
    _isOpen = true;

    final renderBox =
    _overlayKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Obx(() {
        // Rebuild when selection changes to update checkmarks
        _selectedIds.length;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDropdown,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx,
                top: offset.dy + size.height,
                width: size.width,
                child: Material(
                  elevation: 4,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimens.radiusMd),
                    bottomRight: Radius.circular(AppDimens.radiusMd),
                  ),
                  child: _DropdownPanel(
                    searchCtrl: _searchCtrl,
                    searchQuery: _searchQuery,
                    ctrl: ctrl,
                    selectedIds: () => _selectedIds,
                    onPick: _onPick,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Trigger button ─────────────────────────────
        GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            key: _overlayKey,
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(
                color: _isOpen ? AppColors.primary : AppColors.border,
                width: _isOpen ? 1.5 : 1.0,
              ),
              borderRadius: _isOpen
                  ? const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusMd),
                topRight: Radius.circular(AppDimens.radiusMd),
              )
                  : BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.build_outlined,
                    size: 18, color: AppColors.textHint),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(() {
                    final count = _selectedIds.length;
                    String label;
                    if (count == 0) {
                      // Design same, sirf wording mode ke hisaab se
                      label = widget.singleSelect
                          ? 'select_skill_hint'.tr
                          : 'select_skills_placeholder'.tr;
                    } else if (count == 1) {
                      final id = _selectedIds.first;
                      String name = '';
                      try {
                        name = ctrl.allSkills
                            .firstWhere((s) => s.skillId == id)
                            .name ??
                            '';
                      } catch (_) {
                        name = '';
                      }
                      label =
                      name.isEmpty ? 'one_skill_selected'.tr : name;
                    } else {
                      label = 'skills_selected_count'
                          .trParams({'count': '$count'});
                    }
                    return Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KTextStyle.poppins(
                        fs: 13,
                        c: count == 0
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    );
                  }),
                ),
                Obx(() {
                  final count = _selectedIds.length;
                  // Single-select me "1" ka badge bekaar hai — naam
                  // trigger me already dikh raha hai.
                  if (count == 0 || widget.singleSelect) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$count',
                        style: KTextStyle.poppins(
                            fs: 11,
                            fw: FontWeight.w600,
                            c: AppColors.primary)),
                  );
                }),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),

        // ── Selected chips ──────────────────────────────
        Obx(() {
          if (_selectedIds.isEmpty) {
            return const SizedBox.shrink();
          }
          final chips = _selectedIds.map((id) {
            String name = '';
            try {
              name = ctrl.allSkills
                  .firstWhere((s) => s.skillId == id)
                  .name ??
                  '';
            } catch (_) {
              name = id.toString();
            }
            return {'id': id, 'name': name};
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((entry) {
                return InputChip(
                  label: Text(entry['name'] as String? ?? '',
                      style: KTextStyle.poppins(
                          fs: 12, c: AppColors.primary)),
                  backgroundColor:
                  AppColors.primary.withOpacity(0.08),
                  deleteIconColor: AppColors.primary,
                  side: BorderSide(
                      color: AppColors.primary.withOpacity(0.3)),
                  materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
                  onDeleted: () => _onPick(entry['id'] as int),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  final TextEditingController searchCtrl;
  final RxString searchQuery;
  final WorkerRegController ctrl;

  /// Primary aur Additional dono modes ke liye ek hi panel — selection
  /// kahan rakhi hai ye caller batata hai.
  final List<int> Function() selectedIds;
  final void Function(int id) onPick;

  const _DropdownPanel({
    required this.searchCtrl,
    required this.searchQuery,
    required this.ctrl,
    required this.selectedIds,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimens.radiusMd),
          bottomRight: Radius.circular(AppDimens.radiusMd),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              style: KTextStyle.poppins(fs: 13),
              decoration: InputDecoration(
                hintText: 'search_skills_hint'.tr,
                hintStyle:
                KTextStyle.poppins(fs: 12, c: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_outlined,
                    size: 18, color: AppColors.textHint),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusMd),
                  borderSide:
                  const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusMd),
                  borderSide:
                  const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusMd),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) => searchQuery.value = val,
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Options list
          Obx(() {
            final q = searchQuery.value.toLowerCase().trim();
            final filtered = ctrl.allSkills
                .where((s) =>
            q.isEmpty ||
                (s.name ?? '').toLowerCase().contains(q))
                .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                    ctrl.isLoadingSkills.value
                        ? 'loading_ellipsis'.tr
                        : 'no_skills_found'.tr,
                    style: KTextStyle.poppins(
                        fs: 12, c: AppColors.textHint)),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final skill = filtered[i];
                  final sid = skill.skillId ?? -1;
                  final isSelected = selectedIds().contains(sid);
                  return InkWell(
                    onTap: () => onPick(sid),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 150),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded,
                                size: 13, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              skill.name ?? '',
                              style: KTextStyle.poppins(
                                fs: 13,
                                c: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fw: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
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
      appBar: GradientAppBar(title: AppStrings.CreateProfile),
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
                        title: AppStrings.WorkPreferences,
                        subtitle: 'reg3_subtitle'.tr,
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // ── Work State ────────────────────────────────
                      Text(
                        'work_state_label'.tr,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Obx(() {
                        if (ctrl.isLoadingStates.value) {
                          return Container(
                            padding:
                            const EdgeInsets.all(AppDimens.md),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd),
                              border:
                              Border.all(color: AppColors.border),
                            ),
                            child: const SizedBox(
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          );
                        }
                        return DropdownButtonFormField<int>(
                          value: ctrl.selectedState.value?.id,
                          isExpanded: true,
                          hint: Text('select_state_hint'.tr,
                              style: KTextStyle.poppins(
                                  fs: 13, c: AppColors.textHint)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: const Icon(
                                Icons.location_on_outlined),
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
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          items: ctrl.allStates
                              .map((s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                  KTextStyle.poppins(fs: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              try {
                                final sm = ctrl.allStates
                                    .firstWhere((x) => x.id == v);
                                ctrl.selectedState.value = sm;
                              } catch (_) {
                                ctrl.selectedState.value = null;
                              }
                              ctrl.loadCitiesForState(v);
                            }
                          },
                        );
                      }),
                      const SizedBox(height: AppDimens.lg),

                      // ── Work City ─────────────────────────────────
                      Text(
                        AppStrings.WorkCity,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Obx(() {
                        if (ctrl.isLoadingCities.value) {
                          return Container(
                            padding:
                            const EdgeInsets.all(AppDimens.md),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMd),
                              border:
                              Border.all(color: AppColors.border),
                            ),
                            child: const SizedBox(
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value:
                          ctrl.selectedCity.value?.id.toString(),
                          isExpanded: true,
                          hint: Text('select_city_hint'.tr,
                              style: KTextStyle.poppins(
                                  fs: 13, c: AppColors.textHint)),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            prefixIcon: const Icon(
                                Icons.location_on_outlined),
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
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          items: ctrl.allCities
                              .map((c) => DropdownMenuItem<String>(
                              value: c.id.toString(),
                              child: Text(c.name ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                  KTextStyle.poppins(fs: 13))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              try {
                                final cm = ctrl.allCities
                                    .firstWhere(
                                        (x) => x.id.toString() == v);
                                ctrl.selectedCity.value = cm;
                              } catch (_) {
                                ctrl.selectedCity.value = null;
                              }
                            }
                          },
                        );
                      }),
                      const SizedBox(height: AppDimens.lg),

                      SitelinkTextField(
                        label: AppStrings.PreferredArea,
                        hint: 'preferred_area_hint'.tr,
                        controller: ctrl.preferredAreaCtrl,
                        prefixIcon: Icons.map_outlined,
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ── Relocate toggle ───────────────────────────
                      Text(
                        AppStrings.WillingToRelocate,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => Row(
                        children: [
                          _ToggleCard(
                            label: AppStrings.Yes,
                            selected: ctrl.willRelocate.value,
                            onTap: () =>
                            ctrl.willRelocate.value = true,
                          ),
                          const SizedBox(width: 12),
                          _ToggleCard(
                            label: AppStrings.No,
                            selected: !ctrl.willRelocate.value,
                            onTap: () =>
                            ctrl.willRelocate.value = false,
                          ),
                        ],
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // ── Salary type ───────────────────────────────
                      Text(
                        AppStrings.SalaryType,
                        style: KTextStyle.poppins(
                            fs: 12,
                            fw: FontWeight.w500,
                            c: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Obx(() => AppSegmentedControl(
                        options: [
                          AppStrings.Daily,
                          AppStrings.Monthly
                        ],
                        selectedIndex:
                        ctrl.salaryType.value == 'daily'
                            ? 0
                            : 1,
                        onChanged: (i) => ctrl.salaryType.value =
                        i == 0 ? 'daily' : 'monthly',
                      )),
                      const SizedBox(height: AppDimens.lg),

                      // ── Expected salary ───────────────────────────
                      Obx(() => SitelinkTextField(
                        label:
                        '${AppStrings.ExpectedSalary} (₹ ${'per_word'.tr} ${ctrl.salaryType.value})',
                        hint: 'expected_salary_hint'.tr,
                        controller: ctrl.salaryCtrl,
                        prefixIcon:
                        Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                      )),
                      const SizedBox(height: AppDimens.md),

                      // ── Info note ─────────────────────────────────
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
                                'profile_review_24h_note'.tr,
                                style: KTextStyle.poppins(
                                    fs: 12, c: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),

                      Obx(() => CustomButton(
                        label: AppStrings.SubmitProfile,
                        isLoading: ctrl.isSubmitting.value,
                        onTap: () => ctrl.submitStep3(),
                      )),
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
          style: KTextStyle.poppins(fs: 12, c: AppColors.textHint),
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
              color:
              selected ? AppColors.primary : AppColors.border,
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
      appBar: GradientAppBar(title: AppStrings.UploadDocuments),
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
                      text: 'upload_docs_banner'.tr,
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Government ID ──────────────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Text(AppStrings.GovernmentID,
                                  style: KTextStyle.poppins(
                                      fs: 13, fw: FontWeight.w600)),
                              const Spacer(),
                              Obx(() => ctrl.idProofFile.value != null
                                  ? Row(children: [
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 13),
                                const SizedBox(width: 4),
                                Text('doc_added_label'.tr,
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.success)),
                              ])
                                  : Text('doc_required_label'.tr,
                                  style: KTextStyle.poppins(
                                      fs: 11,
                                      c: Colors.red.shade400))),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ID Type dropdown
                          Obx(() => DropdownButtonFormField<String>(
                            value: ctrl.selectedIdType.value,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusSm),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusSm),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusSm),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                            ),
                            items: AppStrings.idTypes
                                .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t,
                                    style: KTextStyle.poppins(
                                        fs: 13))))
                                .toList(),
                            onChanged: (v) =>
                            ctrl.selectedIdType.value =
                                v ?? '',
                          )),
                          const SizedBox(height: 10),

                          // ID preview / upload box
                          Obx(() {
                            final file = ctrl.idProofFile.value;
                            if (file != null) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(
                                        AppDimens.radiusSm),
                                    child: Image.file(
                                      file,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        _ActionPill(
                                          icon: Icons.edit_outlined,
                                          label: 'change_label'.tr,
                                          onTap: () => ctrl
                                              .showImageSourceSheet(
                                            context: context,
                                            onSelect:
                                            ctrl.pickIdProof,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _ActionPill(
                                          icon: Icons
                                              .delete_outline_rounded,
                                          label: 'remove_label'.tr,
                                          isDestructive: true,
                                          onTap: ctrl.removeIdProof,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            return _UploadTapBox(
                              onTap: () =>
                                  ctrl.showImageSourceSheet(
                                    context: context,
                                    onSelect: ctrl.pickIdProof,
                                  ),
                              label: 'tap_to_upload_id'.tr,
                              sublabel: 'camera_or_gallery_sublabel'.tr,
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Experience Certificate ─────────────
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                  Icons.workspace_premium_outlined,
                                  color: AppColors.primary,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'experience_certificate_label'.tr,
                                style: KTextStyle.poppins(
                                    fs: 13, fw: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'cert_upload_hint'.tr,
                            style: KTextStyle.poppins(
                                fs: 11, c: AppColors.textHint),
                          ),
                          const SizedBox(height: 12),

                          // Multiple certificates — worker alag-alag company/
                          // skill ke certificate laga sakta hai.
                          Obx(() => ExperienceCertList(
                                files: ctrl.experienceCerts,
                                isPdf: ctrl.isPdf,
                                onRemove: ctrl.removeExperienceCert,
                                onAdd: () => _showCertPickerSheet(context, ctrl),
                                canAdd: ctrl.experienceCerts.length <
                                    WorkerRegController.maxExperienceCerts,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Police verification note ──────────────────
                    // Submit se theek pehle rakha hai — yahan worker ki
                    // nazar zaroor padti hai. Baad me bataane se job
                    // apply karte waqt surprise hota hai.
                    Container(
                      padding: const EdgeInsets.all(AppDimens.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.local_police_outlined,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'police_verification_note_title'.tr,
                                  style: KTextStyle.poppins(
                                      fs: 12.5,
                                      fw: FontWeight.w700,
                                      c: AppColors.warning),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'police_verification_note_body'.tr,
                                  style: KTextStyle.poppins(
                                      fs: 11.5,
                                      c: AppColors.textSecondary,
                                      height: 1.45),
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

            // Bottom submit bar
            Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.lg,
                AppDimens.md,
                AppDimens.lg,
                AppDimens.md + MediaQuery.of(context).padding.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider)),
              ),
              // Ye final submit hai — saari files (ID, certificate, work
              // photos) ek saath upload hoti hain, isme kaafi time lagta
              // hai. Obx + isLoading zaroori hai: spinner dikhta hai aur
              // CustomButton khud tap block kar deta hai (double submit se
              // bachne ke liye).
              child: Obx(() => CustomButton(
                    label: AppStrings.SubmitForVerification,
                    isLoading: ctrl.isSubmitting.value,
                    onTap: () => ctrl.submitWorkerProfile(),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upload tap box (empty state) ─────────────────────────────────
class _UploadTapBox extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final String sublabel;

  const _UploadTapBox({
    required this.onTap,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.03),
          borderRadius:
          BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.35),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: KTextStyle.poppins(
                    fs: 12,
                    fw: FontWeight.w500,
                    c: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: KTextStyle.poppins(
                    fs: 10, c: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Small pill button (change / remove overlay) ──────────────────
class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    isDestructive ? Colors.red.shade400 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label,
                style: KTextStyle.poppins(fs: 11, c: color)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PROFILE PENDING VIEW
// ═══════════════════════════════════════════════════════════════════
class ProfilePendingView extends StatefulWidget {
  const ProfilePendingView({super.key});

  @override
  State<ProfilePendingView> createState() => _ProfilePendingViewState();
}

class _ProfilePendingViewState extends State<ProfilePendingView> {
  Timer? _autoRedirectTimer;

  @override
  void initState() {
    super.initState();
    // Auto move to dashboard after 3 seconds
    _autoRedirectTimer = Timer(const Duration(seconds: 3), _goToHome);
  }

  @override
  void dispose() {
    _autoRedirectTimer?.cancel();
    super.dispose();
  }

  void _goToHome() {
    _autoRedirectTimer?.cancel();
    Get.offAllNamed(AppRoutes.workerHome);
  }

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
                AppStrings.ProfileUnderReview,
                style: KTextStyle.poppins(
                    fs: 20, fw: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.ProfileUnderReviewSubtitle,
                style: KTextStyle.poppins(
                    fs: 14, c: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.WhatHappensNext,
                      style: KTextStyle.poppins(
                          fs: 13,
                          fw: FontWeight.w600,
                          c: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    _PendingStep(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                      label: 'pending_step_profile_submitted'.tr,
                      isDone: true,
                    ),
                    _PendingStep(
                      icon: Icons.sync_rounded,
                      iconColor: AppColors.primary,
                      label: 'pending_step_admin_reviewing'.tr,
                      isCurrent: true,
                    ),
                    _PendingStep(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.textHint,
                      label: 'pending_step_notification_approved'.tr,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              CustomButton(
                label: AppStrings.GoToHome,
                isOutlined: true,
                onTap: _goToHome,
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
// ── Certificate source picker ───────────────────────────────────────
// Certificate PDF bhi ho sakta hai aur photo bhi, isliye teeno option
// ek sheet me — camera, gallery, PDF.
void _showCertPickerSheet(BuildContext context, WorkerRegController ctrl) {
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
              ctrl.pickExperienceCert(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.primary),
            title: Text('gallery_label'.tr, style: KTextStyle.poppins(fs: 14)),
            onTap: () {
              Get.back();
              ctrl.pickExperienceCert(ImageSource.gallery);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
            title: Text('pdf_label'.tr, style: KTextStyle.poppins(fs: 14)),
            onTap: () {
              Get.back();
              ctrl.pickExperienceCert(null);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
