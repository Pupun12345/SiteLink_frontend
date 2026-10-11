import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/utils/amenity_category_label.dart';
import '../controllers/new_request_controller.dart';
import 'location_picker_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  NEW REQUEST VIEW
// ═══════════════════════════════════════════════════════════════════
class NewRequestView extends StatelessWidget {
  const NewRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(NewRequestController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: AppStrings.NewRequest),
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

                    // ── Pre-filled worker banner ───────────
                    Obx(() {
                      if (ctrl.preFilledWorkerName.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(
                            bottom: AppDimens.md),
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(
                              AppDimens.radiusMd),
                          border: Border.all(
                              color:
                              AppColors.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            AvatarCircle(
                              initials: ctrl.preFilledWorkerName.value
                                  .substring(0, 2)
                                  .toUpperCase(),
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'hiring_prefix'.trParams(
                                        {'name': ctrl.preFilledWorkerName.value}),
                                    style: KTextStyle.poppins(
                                        fs: 13,
                                        fw: FontWeight.w600,
                                        c: AppColors.primary),
                                  ),
                                  Text(
                                    'skill_id_line'.trParams({
                                      'skill': ctrl.preFilledSkill.value,
                                      'id': ctrl.preFilledWorkerId.value,
                                    }),
                                    style: KTextStyle.poppins(
                                        fs: 11,
                                        c: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ctrl.preFilledWorkerName.value = '';
                                ctrl.preFilledWorkerId.value = '';
                                ctrl.preFilledSkill.value = '';
                              },
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ── Section 1: Role Required ───────────
                    _SectionCard(
                      title: AppStrings.RoleRequired,
                      icon: Icons.engineering_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showRolePicker(context, ctrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 13),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: AppColors.border),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusMd),
                              ),
                              child: Row(children: [
                                const Icon(Icons.engineering_outlined,
                                    size: 18, color: AppColors.textHint),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Obx(() {
                                    final count = ctrl.selectedRoles.length;
                                    return Text(
                                      count == 0
                                          ? 'select_roles_placeholder'.tr
                                          : 'roles_selected_count'
                                              .trParams({'count': '$count'}),
                                      style: KTextStyle.poppins(
                                        fs: 13,
                                        c: count == 0
                                            ? AppColors.textHint
                                            : AppColors.textPrimary,
                                      ),
                                    );
                                  }),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 20, color: AppColors.textHint),
                              ]),
                            ),
                          ),
                          Obx(() {
                            if (ctrl.selectedRoles.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: ctrl.selectedRoles.map((s) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.08),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withOpacity(0.3)),
                                    ),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(s,
                                              style: KTextStyle.poppins(
                                                  fs: 12,
                                                  c: AppColors.primary)),
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () => ctrl.selectedRoles
                                                .remove(s),
                                            child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: AppColors.primary),
                                          ),
                                        ]),
                                  );
                                }).toList(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 2: Quantity ────────────────
                    Obx(() => ctrl.selectedRoles.isEmpty
                        ? const SizedBox.shrink()
                        : _SectionCard(
                      title: AppStrings.Quantity,
                      icon: Icons.people_outline_rounded,
                      child: Column(
                        children:
                        ctrl.selectedRoles.map((role) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 10),
                            child: Row(
                              children: [
                                SkillChip(
                                    label: role,
                                    selected: true),
                                const Spacer(),
                                Obx(() => CounterWidget(
                                  value: ctrl.quantities[
                                  role] ??
                                      1,
                                  onIncrement: () => ctrl
                                      .incrementQty(role),
                                  onDecrement: () => ctrl
                                      .decrementQty(role),
                                )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )),
                    Obx(() => ctrl.selectedRoles.isEmpty
                        ? const SizedBox.shrink()
                        : const SizedBox(height: AppDimens.md)),

                    // ── Section 3: Location ────────────────
                    _SectionCard(
                      title: AppStrings.SiteLocation,
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: [
                          SitelinkTextField(
                            label: '${AppStrings.City} *',
                            hint: 'enter_city_hint'.tr,
                            controller: ctrl.cityCtrl,
                            prefixIcon:
                            Icons.location_city_rounded,
                          ),
                          const SizedBox(height: AppDimens.md),
                          SitelinkTextField(
                            label: 'area_landmark_label'.tr,
                            hint: 'area_landmark_hint'.tr,
                            controller: ctrl.areaCtrl,
                            prefixIcon: Icons.place_outlined,
                          ),
                          const SizedBox(height: AppDimens.md),
                          GestureDetector(
                            onTap: () async {
                              final picked = await Get.to<LatLng>(
                                  () => const LocationPickerView());
                              if (picked != null) {
                                ctrl.setPickedLocation(picked);
                              }
                            },
                            child: Obx(() {
                              final set = ctrl.pickedLat.value != null;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border:
                                      Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMd),
                                ),
                                child: Row(children: [
                                  Icon(
                                    set
                                        ? Icons.location_on_rounded
                                        : Icons.map_outlined,
                                    size: 18,
                                    color: set
                                        ? AppColors.success
                                        : AppColors.textHint,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      set
                                          ? 'location_set_change'.tr
                                          : 'pick_location_on_map'.tr,
                                      style: KTextStyle.poppins(
                                        fs: 13,
                                        c: set
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 18, color: AppColors.textHint),
                                ]),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 4: Timeline ────────────────
                    _SectionCard(
                      title: AppStrings.Timeline,
                      icon: Icons.calendar_today_rounded,
                      child: Column(
                        children: [
                          SitelinkTextField(
                            label: AppStrings.StartDate,
                            hint: 'select_date_hint'.tr,
                            controller: ctrl.startDateCtrl,
                            prefixIcon: Icons.event_rounded,
                            readOnly: true,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(
                                    const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                    const Duration(days: 365)),
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme:
                                    const ColorScheme.light(
                                        primary:
                                        AppColors.primary),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (d != null) {
                                // Asli date bhi rakho — backend ko ISO me
                                // yahi jaati hai, text sirf display ke liye.
                                ctrl.startDate.value = d;
                                ctrl.startDateCtrl.text =
                                '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
                              }
                            },
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text(
                            AppStrings.Duration,
                            style: KTextStyle.poppins(
                                fs: 12,
                                fw: FontWeight.w500,
                                c: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Obx(() => DropdownButtonFormField<String>(
                            value:
                            ctrl.duration.value.isEmpty
                                ? null
                                : ctrl.duration.value,
                            isExpanded: true,
                            hint: Text(
                              'select_duration_hint'.tr,
                              style: KTextStyle.poppins(
                                  fs: 13,
                                  c: AppColors.textHint),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(
                                  Icons.timelapse_rounded,
                                  color: AppColors.primary,
                                  size: 22),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              enabledBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5),
                              ),
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14),
                            ),
                            items: AppStrings.durations
                                .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d,
                                    style: KTextStyle
                                        .poppins(fs: 13))))
                                .toList(),
                            onChanged: (v) =>
                            ctrl.duration.value = v ?? '',
                          )),
                          Obx(() => ctrl.duration.value != 'Custom'
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppDimens.md),
                                  child: SitelinkTextField(
                                    label: 'custom_duration_label'.tr,
                                    hint: 'custom_duration_hint'.tr,
                                    controller: ctrl.customDurationCtrl,
                                    prefixIcon: Icons.edit_calendar_outlined,
                                  ),
                                )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 4b: Pay & Experience ───────
                    _SectionCard(
                      title: 'pay_experience_section'.tr,
                      icon: Icons.currency_rupee_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SitelinkTextField(
                            label: 'salary_rupee_label'.tr,
                            hint: 'salary_hint_example'.tr,
                            controller: ctrl.salaryCtrl,
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.payments_outlined,
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text('salary_type'.tr,
                              style: KTextStyle.poppins(
                                  fs: 12,
                                  fw: FontWeight.w500,
                                  c: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Obx(() => Row(
                                children:
                                    ['daily', 'weekly', 'monthly'].map((t) {
                                  final sel = ctrl.salaryType.value == t;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () =>
                                          ctrl.salaryType.value = t,
                                      child: Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 14,
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: sel
                                              ? AppColors.primary
                                              : AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppDimens.radiusMax),
                                          border: Border.all(
                                              color: sel
                                                  ? AppColors.primary
                                                  : AppColors.border),
                                        ),
                                        child: Text(
                                          _salaryTypeLabel(t),
                                          style: KTextStyle.poppins(
                                            fs: 12,
                                            fw: sel
                                                ? FontWeight.w600
                                                : FontWeight.normal,
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
                          const SizedBox(height: AppDimens.md),
                          SitelinkTextField(
                            label: 'experience_required_years_label'.tr,
                            hint: 'experience_hint_example'.tr,
                            controller: ctrl.experienceCtrl,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: AppDimens.md),
                          Obx(() => Row(children: [
                                Expanded(
                                  child: Text('urgent_hiring_question'.tr,
                                      style: KTextStyle.poppins(
                                          fs: 12,
                                          fw: FontWeight.w500,
                                          c: AppColors.textSecondary)),
                                ),
                                Switch(
                                  value: ctrl.isUrgent.value,
                                  onChanged: (v) =>
                                      ctrl.isUrgent.value = v,
                                  activeColor: AppColors.primary,
                                ),
                              ])),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 4c: Amenities & Benefits ───
                    Column(children: [
                      _SectionCard(
                        title: 'amenities_benefits_label'.tr,
                        icon: Icons.card_giftcard_rounded,
                        action: GestureDetector(
                          onTap: () => _showAddAmenity(context, ctrl),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.add_circle_outline_rounded,
                                size: 15, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text('add_label'.tr,
                                style: KTextStyle.poppins(
                                    fs: 12,
                                    fw: FontWeight.w600,
                                    c: AppColors.primary)),
                          ]),
                        ),
                        child: Obx(() {
                          if (ctrl.amenitiesLoading.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.primary),
                                ),
                              ),
                            );
                          }
                          if (ctrl.groupedAmenities.isEmpty) {
                            return Row(children: [
                              Expanded(
                                child: Text(
                                  'no_amenities_loaded'.tr,
                                  style: KTextStyle.poppins(
                                      fs: 12, c: AppColors.textHint),
                                ),
                              ),
                              GestureDetector(
                                onTap: ctrl.loadAmenities,
                                child: Text('retry_label'.tr,
                                    style: KTextStyle.poppins(
                                        fs: 12,
                                        fw: FontWeight.w600,
                                        c: AppColors.primary)),
                              ),
                            ]);
                          }
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: ctrl.groupedAmenities.entries
                                .map((entry) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(entry.key,
                                              style: KTextStyle.poppins(
                                                  fs: 11.5,
                                                  fw: FontWeight.w600,
                                                  c: AppColors
                                                      .textSecondary)),
                                          const SizedBox(height: 6),
                                          Obx(() => Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: entry.value
                                                    .map((a) {
                                                  final numId =
                                                      a.numericId;
                                                  final sel = ctrl
                                                      .selectedAmenityIds
                                                      .contains(numId);
                                                  return GestureDetector(
                                                    onTap: () => ctrl
                                                        .toggleAmenity(
                                                            numId),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: sel
                                                            ? AppColors
                                                                .selectionBg
                                                            : AppColors
                                                                .surface,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    20),
                                                        border: Border.all(
                                                            color: sel
                                                                ? AppColors
                                                                    .primary
                                                                : AppColors
                                                                    .border),
                                                      ),
                                                      child: Text(
                                                        '${a.icon ?? ''} ${a.name ?? ''}'
                                                            .trim(),
                                                        style: KTextStyle
                                                            .poppins(
                                                          fs: 11.5,
                                                          fw: sel
                                                              ? FontWeight
                                                                  .w600
                                                              : FontWeight
                                                                  .normal,
                                                          c: sel
                                                              ? AppColors
                                                                  .primary
                                                              : AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              )),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          );
                        }),
                      ),
                      const SizedBox(height: AppDimens.md),
                    ]),

                    // ── Section 5: Special Requirements ───
                    _SectionCard(
                      title: AppStrings.SpecialRequirements,
                      icon: Icons.note_alt_outlined,
                      child: TextFormField(
                        controller: ctrl.specialReqCtrl,
                        maxLines: 3,
                        style: KTextStyle.poppins(fs: 13),
                        decoration: InputDecoration(
                          hintText: 'special_req_hint'.tr,
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
                          const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.lg),

                    // ── Summary strip ──────────────────────
                    Obx(() {
                      if (ctrl.selectedRoles.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final summary = ctrl.selectedRoles
                          .map((r) =>
                      '${ctrl.quantities[r] ?? 1} ${r.split('/').first.trim()}')
                          .join(' + ');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.selectionBg,
                          borderRadius: BorderRadius.circular(
                              AppDimens.radiusMd),
                          border: Border.all(
                              color: AppColors.primary
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.summarize_outlined,
                                color: AppColors.primary,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$summary  ·  ${ctrl.cityCtrl.text.isEmpty ? 'location_label'.tr : ctrl.cityCtrl.text}  ·  ${ctrl.effectiveDuration.isEmpty ? 'duration'.tr : ctrl.effectiveDuration.split('/').first}',
                                style: KTextStyle.poppins(
                                    fs: 12,
                                    fw: FontWeight.w500,
                                    c: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppDimens.xl),
                  ],
                ),
              ),
            ),

            // ── Sticky Submit ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.lg,
                vertical: AppDimens.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                    top: BorderSide(color: AppColors.divider)),
              ),
              child: Obx(() => CustomButton(
                label: AppStrings.SubmitRequest,
                onTap: ctrl.submitRequest,
                isLoading: ctrl.isLoading.value,
              )),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  // ── Role picker — searchable bottom sheet (scales past a handful) ──
  void _showRolePicker(BuildContext context, NewRequestController ctrl) {
    final searchCtrl = TextEditingController();
    final query = ''.obs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: EdgeInsets.only(
            left: AppDimens.lg,
            right: AppDimens.lg,
            top: AppDimens.md,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + AppDimens.md,
          ),
          child: Column(
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
              const SizedBox(height: 12),
              Text('select_roles_title'.tr,
                  style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: searchCtrl,
                style: KTextStyle.poppins(fs: 13),
                decoration: InputDecoration(
                  hintText: 'search_roles_hint'.tr,
                  hintStyle:
                      KTextStyle.poppins(fs: 12, c: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_outlined,
                      size: 18, color: AppColors.textHint),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onChanged: (v) => query.value = v,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Obx(() {
                  if (ctrl.isLoadingSkills.value && ctrl.allSkills.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  final q = query.value.toLowerCase().trim();
                  final filtered = ctrl.allSkills
                      .where((s) =>
                          q.isEmpty || s.toLowerCase().contains(q))
                      .toList()
                    ..sort(
                        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('no_roles_found'.tr,
                          style: KTextStyle.poppins(
                              fs: 13, c: AppColors.textHint)),
                    );
                  }

                  // Har letter ka pehla index — A-Z bar isse jump karta hai.
                  final firstIndexOfLetter = <String, int>{};
                  for (int i = 0; i < filtered.length; i++) {
                    final letter = filtered[i][0].toUpperCase();
                    firstIndexOfLetter.putIfAbsent(letter, () => i);
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemExtent: _RoleAlphabetIndex.tileExtent,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            return Obx(() {
                              final sel = ctrl.selectedRoles.contains(s);
                              return Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: AppColors.divider,
                                          width: 1)),
                                ),
                                child: CheckboxListTile(
                                  value: sel,
                                  onChanged: (_) {
                                    if (sel) {
                                      ctrl.selectedRoles.remove(s);
                                    } else {
                                      ctrl.selectedRoles.add(s);
                                      ctrl.quantities[s] =
                                          ctrl.quantities[s] ?? 1;
                                    }
                                  },
                                  title: Text(s,
                                      style: KTextStyle.poppins(fs: 13)),
                                  activeColor: AppColors.primary,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              );
                            });
                          },
                        ),
                      ),
                      _RoleAlphabetIndex(
                        availableLetters: firstIndexOfLetter.keys.toSet(),
                        onLetterSelected: (letter) {
                          final idx = firstIndexOfLetter[letter];
                          if (idx == null || !scrollController.hasClients) {
                            return;
                          }
                          final target = (idx * _RoleAlphabetIndex.tileExtent)
                              .clamp(0.0, scrollController.position.maxScrollExtent);
                          scrollController.animateTo(
                            target,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 8),
              SafeArea(
                child: CustomButton(
                  label: 'done_label'.tr,
                  onTap: () => Navigator.pop(sheetCtx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add custom amenity dialog ─────────────────────────────────────
  void _showAddAmenity(BuildContext context, NewRequestController ctrl) {
    final nameCtrl = TextEditingController();
    final category = NewRequestController.amenityCategories.first.obs;
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('add_amenity_title'.tr,
            style: KTextStyle.poppins(fs: 16, fw: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SitelinkTextField(
                label: 'amenity_name_label'.tr,
                controller: nameCtrl,
                hint: 'amenity_name_hint'.tr),
            const SizedBox(height: 12),
            Text('category_label'.tr,
                style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
            const SizedBox(height: 6),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category.value,
                      isExpanded: true,
                      items: NewRequestController.amenityCategories
                          // value backend ka enum rehta hai, label alag.
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(amenityCategoryLabel(c),
                                  style: KTextStyle.poppins(fs: 13))))
                          .toList(),
                      onChanged: (v) => category.value = v ?? category.value,
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text('cancel_label'.tr)),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Get.back();
              ctrl.addCustomAmenity(name, category.value);
            },
            child: Text('add_label'.tr,
                style: KTextStyle.poppins(
                    fs: 13, fw: FontWeight.w600, c: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Salary type chip label — value stays English (backend-matched
  /// `ctrl.salaryType`), only the shown label is translated.
  String _salaryTypeLabel(String t) {
    switch (t) {
      case 'daily':
        return 'daily'.tr;
      case 'weekly':
        return 'weekly_label'.tr;
      case 'monthly':
        return 'monthly'.tr;
      default:
        return t;
    }
  }
}

// ── Section Card ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _SectionCard(
      {required this.title,
      required this.icon,
      required this.child,
      this.action});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.selectionBg,
                  borderRadius:
                  BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(icon,
                    color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: KTextStyle.poppins(
                    fs: 14, fw: FontWeight.w700),
              ),
              if (action != null) ...[const Spacer(), action!],
            ],
          ),
          const SizedBox(height: AppDimens.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppDimens.md),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ROLE PICKER — right-side A-Z fast-scroll index
// ═══════════════════════════════════════════════════════════════════
// Tap ya vertical drag se list us letter ke pehle role tak jump karti hai.
// Jin letters ke roles nahi hai wo dim/disabled dikhte hai lekin drag
// unhe nazdeeki available letter par snap kar deta hai.
class _RoleAlphabetIndex extends StatefulWidget {
  static const double tileExtent = 46.0;
  static const List<String> _alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  final Set<String> availableLetters;
  final ValueChanged<String> onLetterSelected;

  const _RoleAlphabetIndex({
    required this.availableLetters,
    required this.onLetterSelected,
  });

  @override
  State<_RoleAlphabetIndex> createState() => _RoleAlphabetIndexState();
}

class _RoleAlphabetIndexState extends State<_RoleAlphabetIndex> {
  String? _activeLetter;

  String _nearestAvailableLetter(int rawIndex) {
    final clamped = rawIndex.clamp(0, _RoleAlphabetIndex._alphabet.length - 1);
    if (widget.availableLetters.isEmpty) {
      return _RoleAlphabetIndex._alphabet[clamped];
    }
    for (int offset = 0; offset < _RoleAlphabetIndex._alphabet.length; offset++) {
      final down = clamped - offset;
      if (down >= 0 &&
          widget.availableLetters
              .contains(_RoleAlphabetIndex._alphabet[down])) {
        return _RoleAlphabetIndex._alphabet[down];
      }
      final up = clamped + offset;
      if (up < _RoleAlphabetIndex._alphabet.length &&
          widget.availableLetters
              .contains(_RoleAlphabetIndex._alphabet[up])) {
        return _RoleAlphabetIndex._alphabet[up];
      }
    }
    return _RoleAlphabetIndex._alphabet[clamped];
  }

  void _handleTouch(BuildContext context, double globalDy, double barHeight, double barTop) {
    final local = (globalDy - barTop).clamp(0.0, barHeight);
    final rowHeight = barHeight / _RoleAlphabetIndex._alphabet.length;
    final rawIndex = (local / rowHeight).floor();
    final letter = _nearestAvailableLetter(rawIndex);
    if (letter != _activeLetter) {
      setState(() => _activeLetter = letter);
    }
    widget.onLetterSelected(letter);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final barHeight = constraints.maxHeight;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (d) {
              final box = context.findRenderObject() as RenderBox;
              final barTop = box.localToGlobal(Offset.zero).dy;
              _handleTouch(context, d.globalPosition.dy, barHeight, barTop);
            },
            onVerticalDragUpdate: (d) {
              final box = context.findRenderObject() as RenderBox;
              final barTop = box.localToGlobal(Offset.zero).dy;
              _handleTouch(context, d.globalPosition.dy, barHeight, barTop);
            },
            onVerticalDragEnd: (_) => setState(() => _activeLetter = null),
            onTapUp: (d) {
              final box = context.findRenderObject() as RenderBox;
              final barTop = box.localToGlobal(Offset.zero).dy;
              _handleTouch(context, d.globalPosition.dy, barHeight, barTop);
              setState(() => _activeLetter = null);
            },
            child: Container(
              width: 20,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Column(
                children: _RoleAlphabetIndex._alphabet.map((letter) {
                  final isAvailable = widget.availableLetters.contains(letter);
                  final isActive = _activeLetter == letter;
                  // Expanded — sheet resize par bhi 26 letters hamesha
                  // available height ke andar fit hote hai, overflow nahi.
                  return Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        letter,
                        style: KTextStyle.poppins(
                          fs: 9,
                          fw: isActive ? FontWeight.w800 : FontWeight.w600,
                          c: isActive
                              ? AppColors.primary
                              : (isAvailable
                                  ? AppColors.textSecondary
                                  : AppColors.textHint.withValues(alpha: 0.4)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_activeLetter != null)
            Positioned(
              right: 26,
              top: (barHeight / 2) - 24,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _activeLetter!,
                  style: KTextStyle.poppins(
                      fs: 20, fw: FontWeight.w800, c: Colors.white),
                ),
              ),
            ),
        ],
      );
    });
  }
}