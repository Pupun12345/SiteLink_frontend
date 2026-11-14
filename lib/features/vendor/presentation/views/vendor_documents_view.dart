import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/utils/image_pick.dart';
import '../../../../core/utils/tax_id_formats.dart';
import '../../../worker/presentation/controllers/worker_feed_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR VERIFICATION DOCUMENTS — PAN / GST dobara do
// ═══════════════════════════════════════════════════════════════════
// Admin ne verification reject ki ho to vendor yahan se PAN card, GST
// certificate aur dono numbers theek karke dobara bhejta hai. Backend
// (editVendorProfile) inme se kuch bhi badalne par status wapas
// 'pending' karta hai aur admin ko alert bhejta hai.
class VendorDocumentsView extends StatefulWidget {
  final MyProfile? profile;
  const VendorDocumentsView({super.key, this.profile});

  @override
  State<VendorDocumentsView> createState() => _VendorDocumentsViewState();
}

class _VendorDocumentsViewState extends State<VendorDocumentsView> {
  final _picker = ImagePicker();
  late final _panCtrl = TextEditingController(text: widget.profile?.panNumber ?? '');
  late final _gstCtrl = TextEditingController(text: widget.profile?.gstNumber ?? '');
  File? _panImage;
  File? _gstImage;
  bool _saving = false;

  @override
  void dispose() {
    _panCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(void Function(File) set) async {
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('camera_label'.tr),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('gallery_label'.tr),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ]),
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await pickDocumentImage(_picker, source);
      if (picked != null && mounted) setState(() => set(File(picked.path)));
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final pan = _panCtrl.text.trim().toUpperCase();
    final gst = _gstCtrl.text.trim().toUpperCase();
    if (!TaxIdFormats.isValidPan(pan)) {
      AppSnackbar.error(message: 'valid_pan_required_error'.tr);
      return;
    }
    if (!TaxIdFormats.isValidGst(gst)) {
      AppSnackbar.error(message: 'valid_gst_error'.tr);
      return;
    }
    final p = widget.profile;
    final panChanged = pan != (p?.panNumber ?? '').toUpperCase();
    final gstChanged = gst != (p?.gstNumber ?? '').toUpperCase();
    if (_panImage == null && _gstImage == null && !panChanged && !gstChanged) {
      AppSnackbar.warning(message: 'vendor_docs_nothing_changed'.tr);
      return;
    }

    setState(() => _saving = true);
    final res = await VendorApiService().editVendorProfile(
      fields: {
        if (panChanged) 'panNumber': pan,
        if (gstChanged) 'gstNumber': gst,
      },
      panCardImage: _panImage,
      gstCertificate: _gstImage,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.success) {
      Get.back(result: true);
      AppSnackbar.success(message: 'vendor_docs_submitted'.tr);
    } else {
      AppSnackbar.error(message: res.message ?? 'server_error_generic'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: Text('vendor_docs_title'.tr)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          children: [
            if (p?.isRejected == true) _rejectedBanner(p?.rejectionReason),
            _numberField(_panCtrl, 'pan_number_label'.tr, TaxIdFormats.panLength),
            const SizedBox(height: 12),
            _docTile(
              label: 'pan_card_label'.tr,
              newFile: _panImage,
              currentUrl: p?.panCardImage,
              onPick: () => _pick((f) => _panImage = f),
            ),
            const SizedBox(height: 20),
            _numberField(_gstCtrl, 'gst_number'.tr, TaxIdFormats.gstLength),
            const SizedBox(height: 12),
            _docTile(
              label: 'gst_certificate_label'.tr,
              newFile: _gstImage,
              currentUrl: p?.gstCertificate,
              onPick: () => _pick((f) => _gstImage = f),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white))
                    : Text('submit_for_verification'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectedBanner(String? reason) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('vendor_rejected_title'.tr,
                  style: KTextStyle.poppins(
                      fs: 14, fw: FontWeight.w700, c: AppColors.error)),
              if ((reason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(reason!.trim(),
                    style: KTextStyle.poppins(
                        fs: 12.5, c: AppColors.textPrimary, height: 1.4)),
              ],
              const SizedBox(height: 6),
              Text('vendor_rejected_hint'.tr,
                  style: KTextStyle.poppins(
                      fs: 12, c: AppColors.textSecondary, height: 1.4)),
            ]),
          ),
        ]),
      );

  Widget _numberField(TextEditingController c, String label, int max) =>
      TextField(
        controller: c,
        maxLength: max,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(labelText: label, counterText: ''),
      );

  Widget _docTile({
    required String label,
    required File? newFile,
    required String? currentUrl,
    required VoidCallback onPick,
  }) {
    final url = WorkerFeedController.fullUrl(currentUrl);
    Widget preview;
    if (newFile != null) {
      preview = Image.file(newFile, fit: BoxFit.cover);
    } else if (url.isNotEmpty) {
      preview = Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.description_outlined, color: AppColors.textHint));
    } else {
      preview = const Icon(Icons.description_outlined, color: AppColors.textHint);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 64, height: 64, child: Center(child: preview)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: KTextStyle.poppins(fs: 13.5, fw: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              newFile != null ? 'vendor_docs_new_selected'.tr : 'vendor_docs_current'.tr,
              style: KTextStyle.poppins(
                  fs: 11.5,
                  c: newFile != null ? AppColors.success : AppColors.textSecondary),
            ),
          ]),
        ),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: Text('reupload_label'.tr),
        ),
      ]),
    );
  }
}
