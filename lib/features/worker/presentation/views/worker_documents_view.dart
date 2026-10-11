import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/profile_models.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/theme/shared_widgets.dart';
import '../controllers/worker_feed_controller.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER DOCUMENTS VIEW — Settings → My Documents
// ═══════════════════════════════════════════════════════════════════
// /api/profile/me se governmentID aur experienceCertificate (relative
// paths) → full URL → image preview + tap to view fullscreen.
class WorkerDocumentsView extends StatefulWidget {
  const WorkerDocumentsView({super.key});

  @override
  State<WorkerDocumentsView> createState() => _WorkerDocumentsViewState();
}

class _WorkerDocumentsViewState extends State<WorkerDocumentsView> {
  final _api = ProfileApiService();
  MyProfile? _profile;
  bool _loading = true;
  bool _error = false;

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

  /// Fullscreen image viewer (zoom + close).
  void _view(String url) {
    if (url.isEmpty) return;
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error
                ? _ErrorState(onRetry: _load)
                : _content(),
      ),
    );
  }

  Widget _content() {
    final p = _profile!;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.lg),
      children: [
        _DocCard(
          label: AppStrings.GovernmentID,
          icon: Icons.badge_outlined,
          path: p.governmentID,
          onView: _view,
        ),
        const SizedBox(height: AppDimens.md),
        // Ek se zyada certificate ho sakte hain — har ek apna card.
        if (p.experienceCertificate.isEmpty)
          _DocCard(
            label: 'experience_certificate_label'.tr,
            icon: Icons.workspace_premium_outlined,
            path: null,
            onView: _view,
          )
        else
          for (int i = 0; i < p.experienceCertificate.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.md),
            _DocCard(
              // Ek se zyada hon to number bhi dikhao, warna dono card
              // bilkul ek jaise dikhte hain.
              label: p.experienceCertificate.length > 1
                  ? '${'experience_certificate_label'.tr} ${i + 1}'
                  : 'experience_certificate_label'.tr,
              icon: Icons.workspace_premium_outlined,
              path: p.experienceCertificate[i],
              onView: _view,
            ),
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

// ── Single document card ──────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? path;
  final void Function(String url) onView;

  const _DocCard({
    required this.label,
    required this.icon,
    required this.path,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final url = WorkerFeedController.fullUrl(path);
    final hasDoc = url.isNotEmpty;
    return AppCard(
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
            _StatusPill(uploaded: hasDoc),
          ]),
          const SizedBox(height: 12),
          if (hasDoc)
            GestureDetector(
              onTap: () => onView(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: _DocImage(url: url, height: 170),
              ),
            )
          else
            _NotUploaded(),
        ],
      ),
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

// ── Uploaded / Missing pill ───────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool uploaded;
  const _StatusPill({required this.uploaded});

  @override
  Widget build(BuildContext context) {
    final color = uploaded ? AppColors.success : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(uploaded ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 11, color: color),
        const SizedBox(width: 3),
        Text(uploaded ? 'uploaded_label'.tr : 'missing_label'.tr,
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
