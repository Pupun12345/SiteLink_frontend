import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/location_models.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/utils/tax_id_formats.dart';
import '../controllers/vendor_reg_controller.dart';

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
      appBar: GradientAppBar(title: AppStrings.CompanyProfile),
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
                        AppStrings.TellUsAboutYourCompany,
                        style: KTextStyle.poppins(
                            fs: 16, fw: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.EnterCompanyDetails,
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
                  title: 'company_details_section'.tr,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.CompanyName,
                  hint: 'enter_company_name_hint'.tr,
                  controller: ctrl.companyNameCtrl,
                  prefixIcon: Icons.business_rounded,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.ContactPerson,
                  hint: 'enter_name_hint'.tr,
                  controller: ctrl.contactPersonCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.Designation,
                  hint: 'designation_hint'.tr,
                  controller: ctrl.designationCtrl,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: 'email_label'.tr,
                  hint: 'company_email_hint'.tr,
                  controller: ctrl.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppDimens.md),

                // Contact number — `user.phone`. Yahi number baad me OTP se
                // badalta hai (Settings → Change phone number), isliye ise
                // WhatsApp se alag lena zaroori hai.
                SitelinkTextField(
                  label: '${'phone_number_label'.tr} *',
                  hint: 'ten_digit_number_hint'.tr,
                  controller: ctrl.phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: 'whatsapp_number_label'.tr,
                  hint: 'ten_digit_number_hint'.tr,
                  controller: ctrl.whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  maxLength: 10,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Location Section ────────────────────────
                _FieldSectionLabel(
                  icon: Icons.location_on_outlined,
                  title: 'location_area_section'.tr,
                ),
                const SizedBox(height: AppDimens.md),

                Text(
                  'state_label'.tr,
                  style: KTextStyle.poppins(
                      fs: 12,
                      fw: FontWeight.w500,
                      c: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Obx(() => _apiDropdown<StateModel>(
                      value: ctrl.selectedState.value,
                      hint: 'select_state_hint'.tr,
                      icon: Icons.map_outlined,
                      items: ctrl.allStates
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name ?? '',
                                  style: KTextStyle.poppins(fs: 13))))
                          .toList(),
                      onChanged: ctrl.onStateChanged,
                    )),
                const SizedBox(height: AppDimens.md),

                Text(
                  AppStrings.City,
                  style: KTextStyle.poppins(
                      fs: 12,
                      fw: FontWeight.w500,
                      c: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  if (ctrl.isLoadingCities.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
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
                  return _apiDropdown<CityModel>(
                    value: ctrl.selectedCity.value,
                    hint: 'select_city_hint'.tr,
                    icon: Icons.location_on_outlined,
                    items: ctrl.allCities
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name ?? '',
                                style: KTextStyle.poppins(fs: 13))))
                        .toList(),
                    onChanged: (c) => ctrl.selectedCity.value = c,
                  );
                }),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.WorkArea,
                  hint: 'areas_you_hire_hint'.tr,
                  controller: ctrl.workAreaCtrl,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Optional Section ────────────────────────
                _FieldSectionLabel(
                  icon: Icons.receipt_long_rounded,
                  title: 'tax_details_section'.tr,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: 'pan_number_label'.tr,
                  hint: 'pan_hint_example'.tr,
                  controller: ctrl.panCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: TaxIdFormats.panInput,
                  maxLength: TaxIdFormats.panLength,
                ),
                const SizedBox(height: AppDimens.md),

                SitelinkTextField(
                  label: AppStrings.GSTNumber,
                  hint: 'enter_gstin_hint'.tr,
                  controller: ctrl.gstCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: TaxIdFormats.gstInput,
                  maxLength: TaxIdFormats.gstLength,
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Documents Section ───────────────────────
                _FieldSectionLabel(
                  icon: Icons.upload_file_rounded,
                  title: 'documents_label'.tr,
                ),
                const SizedBox(height: AppDimens.md),

                Obx(() => _DocUploadTile(
                      label: 'pan_card_photo_label'.tr,
                      file: ctrl.panCardImage.value,
                      onPick: (src) => ctrl.pickFile(ctrl.panCardImage, src),
                      onRemove: () => ctrl.panCardImage.value = null,
                    )),
                const SizedBox(height: AppDimens.md),

                Obx(() => _DocUploadTile(
                      label: '${'gst_certificate_label'.tr} *',
                      file: ctrl.gstCertificate.value,
                      onPick: (src) => ctrl.pickFile(ctrl.gstCertificate, src),
                      onRemove: () => ctrl.gstCertificate.value = null,
                    )),
                const SizedBox(height: AppDimens.md),

                Obx(() => _DocUploadTile(
                      label: 'company_logo_optional_label'.tr,
                      file: ctrl.companyLogo.value,
                      onPick: (src) => ctrl.pickFile(ctrl.companyLogo, src),
                      onRemove: () => ctrl.companyLogo.value = null,
                    )),
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
                              AppStrings.YourAccountWillBeActivatedWithin12HoursAfterReview,
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
                          AppStrings.AccountWillBeActivatedSoon,
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
                  label: AppStrings.CreateAccount,
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

// ── API-driven dropdown (state/city) ──────────────────────────────
Widget _apiDropdown<T>({
  required T? value,
  required String hint,
  required IconData icon,
  required List<DropdownMenuItem<T>> items,
  required void Function(T?) onChanged,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    isExpanded: true,
    hint: Text(hint, style: KTextStyle.poppins(fs: 13, c: AppColors.textHint)),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    items: items,
    onChanged: onChanged,
  );
}

// ── Document upload tile (pick camera/gallery + preview) ───────────
class _DocUploadTile extends StatelessWidget {
  final String label;
  final File? file;
  final void Function(ImageSource) onPick;
  final VoidCallback onRemove;

  const _DocUploadTile({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  void _showSourceSheet(BuildContext context) {
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
              onPick(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('gallery_label'.tr),
            onTap: () {
              Get.back();
              onPick(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: KTextStyle.poppins(
                fs: 12, fw: FontWeight.w500, c: AppColors.textSecondary)),
        const SizedBox(height: 6),
        if (hasFile)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: Image.file(file!,
                  height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
          ])
        else
          GestureDetector(
            onTap: () => _showSourceSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(children: [
                const Icon(Icons.cloud_upload_outlined,
                    color: AppColors.primary, size: 26),
                const SizedBox(height: 6),
                Text('tap_to_upload_label'.tr,
                    style:
                        KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
              ]),
            ),
          ),
      ],
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