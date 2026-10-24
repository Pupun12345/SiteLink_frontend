import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/app_snackbar.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../../../../core/utils/image_pick.dart';
import '../controllers/worker_feed_controller.dart';
import '../controllers/worker_profile_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER DOCUMENTS VIEW — Settings → My Documents
// ═══════════════════════════════════════════════════════════════════
// /api/profile/me se governmentID aur experienceCertificate (relative
// paths) → full URL → image preview + tap to view fullscreen.
//
// Registration ke baad bhi documents yahin se add / re-upload hote hain:
//   • jo document missing hai → "Upload"
//   • Government ID admin ne reject ki → "Re-upload" (sirf ID ka review hota hai)
//   • experience certificates ka review nahi — vendor ko dikhane ke liye,
//     worker kabhi bhi badle / hataye
//   • experience certificate kabhi bhi aur jode ja sakte hain (max 5)
// Rejected ke baad naya upload karne par backend status wapas 'pending'
// kar deta hai, taaki admin dobara review kare.
class WorkerDocumentsView extends StatefulWidget {
  const WorkerDocumentsView({super.key});

  @override
  State<WorkerDocumentsView> createState() => _WorkerDocumentsViewState();
}

class _WorkerDocumentsViewState extends State<WorkerDocumentsView> {
  static const _maxCerts = 5;

  final _api = ProfileApiService();
  final _workerApi = WorkerApiService();
  final _picker = ImagePicker();
  MyProfile? _profile;
  bool _loading = true;
  bool _error = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await _api.getMe();
      if (res.success && res.user != null) {
        _profile = res.user;
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Upload ──────────────────────────────────────────────────────
  /// Camera / gallery (aur certificate ke liye PDF) chooser. Chuni hui
  /// file return karta hai, ya null agar user ne cancel kiya.
  Future<File?> _pickFile({required bool allowPdf}) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: Text('camera_label'.tr, style: KTextStyle.poppins(fs: 14)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title:
                  Text('gallery_label'.tr, style: KTextStyle.poppins(fs: 14)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (allowPdf)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: Colors.red),
                title: Text('pdf_label'.tr, style: KTextStyle.poppins(fs: 14)),
                onTap: () => Navigator.pop(ctx, 'pdf'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return null;

    try {
      if (choice == 'pdf') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        final path = result?.files.single.path;
        return path == null ? null : File(path);
      }
      final picked = await pickDocumentImage(_picker,
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery);
      return picked == null ? null : File(picked.path);
    } catch (_) {
      AppSnackbar.error(message: 'image_pick_failed'.tr);
      return null;
    }
  }

  Future<void> _upload({
    File? governmentID,
    File? certificate,
    List<String>? keepCertificates,
    String successKey = 'docs_upload_success',
  }) async {
    setState(() => _uploading = true);
    try {
      final res = await _workerApi.editWorkerProfile(
        governmentID: governmentID,
        experienceCertificates: certificate == null ? null : [certificate],
        keepExperienceCertificates: keepCertificates,
      );
      if (!mounted) return;
      if (res.success) {
        if (Get.isRegistered<WorkerProfileController>()) {
          Get.find<WorkerProfileController>().fetchProfile();
        }
        await _load();
        // Aur rejected documents baaki hain to batao — tab tak admin ke
        // paas review ke liye nahi jaata.
        final left = _rejectedCount(_profile);
        if (left > 0) {
          AppSnackbar.warning(
              message: 'docs_more_to_reupload'.trParams({'count': '$left'}));
        } else {
          AppSnackbar.success(message: successKey.tr);
        }
      } else {
        AppSnackbar.error(message: res.message ?? 'docs_upload_failed'.tr);
      }
    } catch (_) {
      AppSnackbar.error(message: 'docs_upload_failed'.tr);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Abhi kitne documents rejected hain (jo dobara upload karne hain).
  static int _rejectedCount(MyProfile? p) {
    if (p == null || !p.isRejected || !p.hasDocumentRejections) return 0;
    // Sirf Government ID ka review hota hai.
    return (p.reviewFor(p.governmentID)?.isRejected ?? false) ? 1 : 0;
  }

  Future<void> _uploadGovtId() async {
    final file = await _pickFile(allowPdf: false);
    if (file != null) await _upload(governmentID: file);
  }

  /// [replaceIndex] null = naya certificate jodo; warna us index wala
  /// certificate naye se badlo (baaki waise hi rehte hain).
  Future<void> _uploadCert({int? replaceIndex}) async {
    final certs = _profile?.experienceCertificate ?? const <String>[];
    if (replaceIndex == null && certs.length >= _maxCerts) {
      AppSnackbar.warning(
          message: 'max_certificates_error'.trParams({'count': '$_maxCerts'}));
      return;
    }
    final file = await _pickFile(allowPdf: true);
    if (file == null) return;
    await _upload(
      certificate: file,
      // Certificate ka review nahi hota — "admin review karega" mat bolo.
      successKey: 'certificate_saved_success',
      keepCertificates: replaceIndex == null
          ? null
          : [
              for (int i = 0; i < certs.length; i++)
                if (i != replaceIndex) certs[i],
            ],
    );
  }

  /// Certificate hatao (naya upload kiye bina) — baaki waise hi.
  Future<void> _removeCert(int index) async {
    final certs = _profile?.experienceCertificate ?? const <String>[];
    final ok = await Get.dialog<bool>(AlertDialog(
      title: Text('remove_certificate_title'.tr,
          style: KTextStyle.poppins(fs: 16, fw: FontWeight.w600)),
      content: Text('remove_certificate_body'.tr,
          style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel_label'.tr)),
        TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('remove_label'.tr,
                style: const TextStyle(color: AppColors.error))),
      ],
    ));
    if (ok != true) return;
    await _upload(
      keepCertificates: [
        for (int i = 0; i < certs.length; i++)
          if (i != index) certs[i],
      ],
      successKey: 'certificate_removed_success',
    );
  }

  /// Fullscreen image viewer (zoom + close). PDF bahar ke app me khulta hai.
  void _view(String url) {
    if (url.isEmpty) return;
    if (_isPdf(url)) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 54),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(title: 'my_documents'.tr),
      body: SafeArea(
        top: false,
        child: Stack(children: [
          // Upload ke baad reload par list wahi rehti hai (poora spinner nahi).
          _loading && _profile == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _error
                  ? _ErrorState(onRetry: _load)
                  : _content(),
          if (_uploading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: AppCard(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text('docs_uploading'.tr,
                          style: KTextStyle.poppins(fs: 13)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _content() {
    final p = _profile!;
    // Uploaded document tabhi badla ja sakta hai jab admin ne use reject
    // kiya ho (p.canReplaceDocument). Missing document upload aur naye
    // certificate jodna hamesha khula.
    final certs = p.experienceCertificate;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.lg),
      children: [
        _StatusBanner(profile: p),
        const SizedBox(height: AppDimens.md),
        _DocCard(
          label: AppStrings.GovernmentID,
          icon: Icons.badge_outlined,
          path: p.governmentID,
          onView: _view,
          review: p.reviewFor(p.governmentID),
          canReplace: p.canReplaceDocument(p.governmentID),
          onUpload: _uploadGovtId,
        ),
        const SizedBox(height: AppDimens.md),
        // Ek se zyada certificate ho sakte hain — har ek apna card.
        if (certs.isEmpty)
          _DocCard(
            label: 'experience_certificate_label'.tr,
            icon: Icons.workspace_premium_outlined,
            path: null,
            onView: _view,
            canReplace: false,
            onUpload: () => _uploadCert(),
          )
        else ...[
          for (int i = 0; i < certs.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.md),
            _DocCard(
              // Ek se zyada hon to number bhi dikhao, warna dono card
              // bilkul ek jaise dikhte hain.
              label: certs.length > 1
                  ? '${'experience_certificate_label'.tr} ${i + 1}'
                  : 'experience_certificate_label'.tr,
              icon: Icons.workspace_premium_outlined,
              path: certs[i],
              onView: _view,
              // Certificate ka admin review nahi hota (sirf vendor ko dikhane
              // ke liye) — worker kabhi bhi badal ya hata sakta hai.
              reviewable: false,
              canReplace: true,
              onUpload: () => _uploadCert(replaceIndex: i),
              onRemove: () => _removeCert(i),
            ),
          ],
          if (certs.length < _maxCerts) ...[
            const SizedBox(height: AppDimens.md),
            CustomButton(
              label: 'add_more_certificate'.tr,
              isOutlined: true,
              leading: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primary),
              onTap: () => _uploadCert(),
            ),
          ],
        ],
        const SizedBox(height: AppDimens.lg),
        Row(children: [
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'docs_secure_note'.tr,
              style: KTextStyle.poppins(fs: 11, c: AppColors.textHint),
            ),
          ),
        ]),
      ],
    );
  }
}

bool _isPdf(String url) =>
    url.toLowerCase().split('?').first.endsWith('.pdf');

// ── Verification status banner (pending / verified / rejected) ────
class _StatusBanner extends StatelessWidget {
  final MyProfile profile;
  const _StatusBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final String title;
    final String? note;
    final Color color;
    final IconData icon;
    if (profile.isVerified) {
      title = 'docs_status_verified'.tr;
      note = null;
      color = AppColors.success;
      icon = Icons.verified_rounded;
    } else if (profile.isRejected && profile.hasDocumentRejections) {
      // Admin ne Government ID reject ki — sirf wahi dobara chahiye.
      title = 'docs_need_reupload_title'.tr;
      note = 'docs_need_reupload_note'.tr;
      color = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (profile.isRejected) {
      final reason = (profile.rejectionReason ?? '').trim();
      title = 'docs_status_rejected'.tr;
      note = reason.isEmpty
          ? 'docs_status_rejected_note'.tr
          : '${'docs_rejected_reason'.trParams({'reason': reason})}\n'
              '${'docs_status_rejected_note'.tr}';
      color = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else {
      title = 'docs_status_pending'.tr;
      note = 'docs_status_pending_note'.tr;
      color = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600, c: color)),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(note,
                  style:
                      KTextStyle.poppins(fs: 11.5, c: AppColors.textSecondary)),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Single document card ──────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final void Function(String url) onView;
  /// Admin ka is document par review (null = abhi review nahi hua).
  final DocumentReview? review;
  /// Uploaded document badla ja sakta hai? (admin ne ise reject kiya hai)
  final bool canReplace;
  final VoidCallback onUpload;
  /// Certificate hatane ke liye (ID proof ke liye null).
  final VoidCallback? onRemove;
  /// Admin is document ko review karta hai? Sirf Government ID — certificate
  /// par koi review status nahi dikhate.
  final bool reviewable;

  const _DocCard({
    required this.label,
    required this.icon,
    required this.path,
    required this.onView,
    required this.canReplace,
    required this.onUpload,
    this.review,
    this.onRemove,
    this.reviewable = true,
  });

  @override
  Widget build(BuildContext context) {
    final url = WorkerFeedController.fullUrl(path);
    final hasDoc = url.isNotEmpty;
    final rejected = reviewable && hasDoc && (review?.isRejected ?? false);
    final reason = (review?.reason ?? '').trim();
    final card = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600)),
            ),
            _StatusPill(
              state: !hasDoc
                  ? _DocState.missing
                  : !reviewable
                      ? _DocState.uploaded
                  : rejected
                      ? _DocState.rejected
                      : (review?.isApproved ?? false)
                          ? _DocState.approved
                          : _DocState.inReview,
            ),
          ]),
          // Admin ne kyun reject kiya — worker ko pata ho kya theek karna hai.
          if (rejected) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reason.isEmpty
                        ? 'doc_rejected_no_reason'.tr
                        : 'docs_rejected_reason'.trParams({'reason': reason}),
                    style: KTextStyle.poppins(fs: 12, c: AppColors.error),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          if (hasDoc)
            GestureDetector(
              onTap: () => onView(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: _isPdf(url)
                    ? const _PdfTile(height: 110)
                    : _DocImage(url: url, height: 170),
              ),
            )
          else
            _NotUploaded(),
          // Missing → hamesha upload; uploaded → sirf reject hone par.
          if (!hasDoc || canReplace) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: CustomButton(
                  label: hasDoc ? 'reupload_label'.tr : 'upload_label'.tr,
                  // Rejected par bhara hua button — yahi asli kaam hai.
                  isOutlined: hasDoc && !rejected,
                  height: 40,
                  leading: Icon(
                      hasDoc ? Icons.refresh_rounded : Icons.upload_rounded,
                      size: 18,
                      color: hasDoc && !rejected
                          ? AppColors.primary
                          : Colors.white),
                  onTap: onUpload,
                ),
              ),
              if (hasDoc && onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'remove_label'.tr,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
              ],
            ]),
          ],
        ],
      ),
    );

    // Rejected card ko laal border — list me turant dikh jaaye.
    if (!rejected) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.6), width: 1.5),
      ),
      child: card,
    );
  }
}

// ── PDF placeholder (Image.network PDF nahi dikha sakta) ─────────
class _PdfTile extends StatelessWidget {
  final double height;
  const _PdfTile({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.scaffoldBg,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 34),
        const SizedBox(height: 6),
        Text('pdf_label'.tr,
            style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary)),
      ]),
    );
  }
}

// ── Network image with loading / error states ─────────────────────
class _DocImage extends StatelessWidget {
  final String url;
  final double height;
  const _DocImage({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: double.infinity,
          color: AppColors.scaffoldBg,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: AppColors.scaffoldBg,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.textHint, size: 28),
      ),
    );
  }
}

// ── "Not uploaded" placeholder ────────────────────────────────────
class _NotUploaded extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: [
        const Icon(Icons.upload_file_outlined,
            color: AppColors.textHint, size: 26),
        const SizedBox(height: 6),
        Text('not_uploaded_label'.tr,
            style: KTextStyle.poppins(fs: 12, c: AppColors.textHint)),
      ]),
    );
  }
}

// ── Document ka haal: Approved / Rejected / Under review / Missing ──
enum _DocState { missing, uploaded, inReview, approved, rejected }

class _StatusPill extends StatelessWidget {
  final _DocState state;
  const _StatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (state) {
      _DocState.missing =>
        (AppColors.textHint, Icons.remove_circle_outline, 'missing_label'.tr),
      _DocState.uploaded =>
        (AppColors.success, Icons.check_circle_rounded, 'uploaded_label'.tr),
      _DocState.inReview =>
        (AppColors.warning, Icons.hourglass_top_rounded, 'doc_in_review_label'.tr),
      _DocState.approved =>
        (AppColors.success, Icons.check_circle_rounded, 'doc_approved_label'.tr),
      _DocState.rejected =>
        (AppColors.error, Icons.cancel_rounded, 'doc_rejected_label'.tr),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: KTextStyle.poppins(
                fs: 9.5, fw: FontWeight.w600, c: color)),
      ]),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded,
              size: 42, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('documents_load_failed'.tr,
              style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: CustomButton(label: 'retry_label'.tr, onTap: onRetry),
          ),
        ]),
      ),
    );
  }
}
