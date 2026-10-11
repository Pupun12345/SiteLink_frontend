import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/utils/tax_id_formats.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/edit_vendor_profile_controller.dart';
import '../../../shared/presentation/views/change_phone_sheet.dart';

// ═══════════════════════════════════════════════════════════════════
//  EDIT VENDOR PROFILE VIEW
// ═══════════════════════════════════════════════════════════════════
class EditVendorProfileView extends StatelessWidget {
  const EditVendorProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(EditVendorProfileController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'edit_company_profile_title'.tr),
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
                _logoSection(context, ctrl),
                const SizedBox(height: AppDimens.lg),
                _card('company_details_section'.tr, Icons.business_rounded, [
                  SitelinkTextField(
                      label: 'company_name'.tr,
                      controller: ctrl.companyNameCtrl,
                      hint: 'company_name_hint'.tr),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'contact_person'.tr,
                      controller: ctrl.nameCtrl,
                      hint: 'your_name_hint'.tr),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'designation'.tr,
                      controller: ctrl.designationCtrl,
                      hint: 'designation_hint_short'.tr),
                ]),
                const SizedBox(height: AppDimens.md),
                _card('contact_section'.tr, Icons.contact_phone_outlined, [
                  Text('phone_number_label'.tr,
                      style: KTextStyle.poppins(fs: 12, fw: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: Row(children: [
                          const Icon(Icons.phone_android_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ctrl.currentPhone.value.isNotEmpty
                                  ? '+91 ${ctrl.currentPhone.value}'
                                  : 'not_set_label'.tr,
                              style: KTextStyle.poppins(fs: 13.5),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showChangePhoneSheet(
                              context,
                              onUpdated: (newPhone) =>
                                  ctrl.currentPhone.value = newPhone,
                            ),
                            child: Text('change_label'.tr,
                                style: KTextStyle.poppins(
                                    fs: 12.5,
                                    fw: FontWeight.w700,
                                    c: AppColors.primary)),
                          ),
                        ]),
                      )),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'email_label'.tr,
                      controller: ctrl.emailCtrl,
                      hint: 'company_email_hint'.tr,
                      keyboardType: TextInputType.emailAddress,
                      ),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'whatsapp_number_label'.tr,
                      controller: ctrl.whatsappCtrl,
                      hint: 'ten_digit_hint'.tr,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      maxLength: 10),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'website_label'.tr,
                      controller: ctrl.websiteCtrl,
                      hint: 'website_hint'.tr,
                      ),
                ]),
                const SizedBox(height: AppDimens.md),
                _card('location_tax_section'.tr, Icons.location_on_outlined, [
                  Text('state_label'.tr,
                      style: KTextStyle.poppins(
                          fs: 12, fw: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => _dropdown<StateModel>(
                        value: ctrl.selectedState.value,
                        hint: 'select_state_hint'.tr,
                        items: ctrl.allStates
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name ?? '',
                                    style: KTextStyle.poppins(fs: 13))))
                            .toList(),
                        onChanged: ctrl.onStateChanged,
                      )),
                  const SizedBox(height: 12),
                  Text('city_label'.tr,
                      style: KTextStyle.poppins(
                          fs: 12, fw: FontWeight.w600)),
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
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name ?? '',
                                  style: KTextStyle.poppins(fs: 13))))
                          .toList(),
                      onChanged: ctrl.onCityChanged,
                    );
                  }),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'work_area'.tr,
                      controller: ctrl.workAreaCtrl,
                      hint: 'areas_you_hire_hint'.tr,
                      ),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'gst_number'.tr,
                      controller: ctrl.gstCtrl,
                      hint: 'gstin_hint'.tr,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: TaxIdFormats.gstInput,
                      maxLength: TaxIdFormats.gstLength,
                      ),
                ]),
                const SizedBox(height: AppDimens.xl),
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2)),
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

  Widget _logoSection(BuildContext context, EditVendorProfileController ctrl) {
    return Center(
      child: Obx(() {
        final newLogo = ctrl.newLogo.value;
        final url = WorkerFeedController.fullUrl(ctrl.currentLogoUrl.value);
        return Stack(children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.selectionBg,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: newLogo != null
                ? Image.file(newLogo, fit: BoxFit.cover)
                : url.isNotEmpty
                    ? Image.network(url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.business_rounded,
                            color: AppColors.primary,
                            size: 40))
                    : const Icon(Icons.business_rounded,
                        color: AppColors.primary, size: 40),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickSheet(context, ctrl),
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

  void _pickSheet(BuildContext context, EditVendorProfileController ctrl) {
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
              ctrl.pickLogo(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('gallery_label'.tr),
            onTap: () {
              Get.back();
              ctrl.pickLogo(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
            Text(title,
                style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

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
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
