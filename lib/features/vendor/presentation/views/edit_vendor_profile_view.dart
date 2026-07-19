import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';
import '../controllers/edit_vendor_profile_controller.dart';
import 'change_phone_sheet.dart';

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
      appBar: GradientAppBar(title: 'Edit Company Profile'),
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
                _card('Company Details', Icons.business_rounded, [
                  SitelinkTextField(
                      label: 'Company Name',
                      controller: ctrl.companyNameCtrl,
                      hint: 'Company name'),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'Contact Person',
                      controller: ctrl.nameCtrl,
                      hint: 'Your name'),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'Designation',
                      controller: ctrl.designationCtrl,
                      hint: 'e.g. Owner, Manager'),
                ]),
                const SizedBox(height: AppDimens.md),
                _card('Contact', Icons.contact_phone_outlined, [
                  Text('Phone Number',
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
                                  : 'Not set',
                              style: KTextStyle.poppins(fs: 13.5),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showChangePhoneSheet(context, ctrl),
                            child: Text('Change',
                                style: KTextStyle.poppins(
                                    fs: 12.5,
                                    fw: FontWeight.w700,
                                    c: AppColors.primary)),
                          ),
                        ]),
                      )),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'Email',
                      controller: ctrl.emailCtrl,
                      hint: 'company@email.com',
                      keyboardType: TextInputType.emailAddress,
                      isOptional: true),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'WhatsApp Number',
                      controller: ctrl.whatsappCtrl,
                      hint: '10-digit',
                      keyboardType: TextInputType.phone,
                      isOptional: true),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'Website',
                      controller: ctrl.websiteCtrl,
                      hint: 'https://...',
                      isOptional: true),
                ]),
                const SizedBox(height: AppDimens.md),
                _card('Location & Tax', Icons.location_on_outlined, [
                  Text('State',
                      style: KTextStyle.poppins(
                          fs: 12, fw: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => _dropdown<StateModel>(
                        value: ctrl.selectedState.value,
                        hint: 'Select state',
                        items: ctrl.allStates
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name ?? '',
                                    style: KTextStyle.poppins(fs: 13))))
                            .toList(),
                        onChanged: ctrl.onStateChanged,
                      )),
                  const SizedBox(height: 12),
                  Text('City',
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
                      hint: 'Select city',
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
                      label: 'Work Area',
                      controller: ctrl.workAreaCtrl,
                      hint: 'Areas where you hire',
                      isOptional: true),
                  const SizedBox(height: 12),
                  SitelinkTextField(
                      label: 'GST Number',
                      controller: ctrl.gstCtrl,
                      hint: 'GSTIN',
                      isOptional: true),
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
                label: 'Save Changes',
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
            title: const Text('Camera'),
            onTap: () {
              Get.back();
              ctrl.pickLogo(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
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
