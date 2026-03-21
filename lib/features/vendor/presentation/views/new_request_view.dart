import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/new_request_controller.dart';

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
      appBar: GradientAppBar(title: AppStrings.newRequestTitle),
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
                    // ── Section 1: Role Required ───────────
                    _SectionCard(
                      title: AppStrings.roleRequired,
                      icon: Icons.engineering_rounded,
                      child: Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppStrings.allSkills.map((s) {
                          final sel =
                          ctrl.selectedRoles.contains(s);
                          return GestureDetector(
                            onTap: () => sel
                                ? ctrl.selectedRoles.remove(s)
                                : ctrl.selectedRoles.add(s),
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
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
                                s,
                                style: KTextStyle.poppins(
                                  fs: 12,
                                  fw: sel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  c: sel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 2: Quantity ────────────────
                    Obx(() => ctrl.selectedRoles.isEmpty
                        ? const SizedBox.shrink()
                        : _SectionCard(
                      title: AppStrings.quantity,
                      icon: Icons.people_outline_rounded,
                      child: Column(
                        children: ctrl.selectedRoles.map((role) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 10),
                            child: Row(
                              children: [
                                SkillChip(
                                    label: role, selected: true),
                                const Spacer(),
                                Obx(() => CounterWidget(
                                  value:
                                  ctrl.quantities[role] ??
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
                      title: AppStrings.siteLocation,
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: [
                          SitelinkTextField(
                            label: '${AppStrings.city} *',
                            hint: 'Enter city',
                            controller: ctrl.cityCtrl,
                            prefixIcon:
                            Icons.location_city_rounded,
                          ),
                          const SizedBox(height: AppDimens.md),
                          SitelinkTextField(
                            label: 'Area / Landmark',
                            hint:
                            'Area or landmark (optional)',
                            controller: ctrl.areaCtrl,
                            prefixIcon: Icons.place_outlined,
                            isOptional: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 4: Timeline ────────────────
                    _SectionCard(
                      title: AppStrings.timeline,
                      icon: Icons.calendar_today_rounded,
                      child: Column(
                        children: [
                          SitelinkTextField(
                            label: AppStrings.startDate,
                            hint: 'Select date',
                            controller: ctrl.startDateCtrl,
                            prefixIcon: Icons.event_rounded,
                            readOnly: true,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now()
                                    .add(const Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                    const Duration(days: 365)),
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
                                ctrl.startDateCtrl.text =
                                '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
                              }
                            },
                          ),
                          const SizedBox(height: AppDimens.md),
                          Text(
                            AppStrings.duration,
                            style: KTextStyle.poppins(
                                fs: 12,
                                fw: FontWeight.w500,
                                c: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Obx(() => DropdownButtonFormField<String>(
                            value: ctrl.duration.value.isEmpty
                                ? null
                                : ctrl.duration.value,
                            hint: Text(
                              'Select duration',
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
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    AppDimens.radiusMd),
                                borderSide: const BorderSide(
                                    color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
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
                                    style: KTextStyle.poppins(
                                        fs: 13))))
                                .toList(),
                            onChanged: (v) =>
                            ctrl.duration.value = v ?? '',
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.md),

                    // ── Section 5: Special Requirements ───
                    _SectionCard(
                      title: AppStrings.specialReq,
                      icon: Icons.note_alt_outlined,
                      child: TextFormField(
                        controller: ctrl.specialReqCtrl,
                        maxLines: 3,
                        style: KTextStyle.poppins(fs: 13),
                        decoration: InputDecoration(
                          hintText:
                          'Any specific requirements like tools, experience level, shift...',
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
                                color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(14),
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
                                '$summary  ·  ${ctrl.cityCtrl.text.isEmpty ? 'Location' : ctrl.cityCtrl.text}  ·  ${ctrl.duration.value.isEmpty ? 'Duration' : ctrl.duration.value.split('/').first}',
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
              child: Obx(() => CustomButton(
                label: AppStrings.submitRequest,
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
}

// ── Section Card ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title,
        required this.icon,
        required this.child});

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