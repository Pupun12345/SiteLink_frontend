import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  EXPERIENCE CERTIFICATES — multiple files ki list
// ═══════════════════════════════════════════════════════════════════
// Worker alag-alag company ya skill ke ek se zyada certificate laga
// sakta hai. Har ek PDF ho sakta hai ya photo.
//
// Registration aur Edit Profile dono yahi widget use karte hain, isliye
// dikhne aur behave karne me farak nahi rehta. Edit me purane
// (server par pade) certificates bhi dikhte hain, isliye do list hain:
// [urls] purane aur [files] naye.

class ExperienceCertList extends StatelessWidget {
  /// Naye chune gaye local files.
  final List<File> files;

  /// Server par pehle se pade certificates (full URLs). Sirf Edit me.
  final List<String> urls;

  /// File PDF hai ya nahi — PDF ka preview nahi banta, icon dikhate hain.
  final bool Function(File) isPdf;

  final void Function(int index) onRemove;

  /// Purana (server wala) certificate hataane ke liye. Edit me hi milta hai.
  final void Function(int index)? onRemoveUrl;

  final VoidCallback onAdd;

  /// Limit tak pahunch gaye to "Add" tile chhupa dete hain.
  final bool canAdd;

  const ExperienceCertList({
    super.key,
    required this.files,
    required this.isPdf,
    required this.onRemove,
    required this.onAdd,
    required this.canAdd,
    this.urls = const [],
    this.onRemoveUrl,
  });

  bool get _isEmpty => files.isEmpty && urls.isEmpty;

  @override
  Widget build(BuildContext context) {
    // Kuch bhi nahi hai — teen bade upload options dikhao (pehle jaisa).
    if (_isEmpty) {
      return _AddTile(onTap: onAdd, wide: true);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < urls.length; i++)
          _Thumb(
            url: urls[i],
            isPdfFile: urls[i].toLowerCase().endsWith('.pdf'),
            onRemove: onRemoveUrl == null ? null : () => onRemoveUrl!(i),
          ),
        for (int i = 0; i < files.length; i++)
          _Thumb(
            file: files[i],
            isPdfFile: isPdf(files[i]),
            onRemove: () => onRemove(i),
          ),
        if (canAdd) _AddTile(onTap: onAdd),
      ],
    );
  }
}

// ── Ek certificate ka thumbnail ────────────────────────────────────
class _Thumb extends StatelessWidget {
  final File? file;
  final String? url;
  final bool isPdfFile;
  final VoidCallback? onRemove;

  const _Thumb({
    this.file,
    this.url,
    required this.isPdfFile,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: isPdfFile
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.red, size: 30),
                    const SizedBox(height: 4),
                    Text('pdf_label'.tr,
                        style: KTextStyle.poppins(
                            fs: 10, c: AppColors.textSecondary)),
                  ],
                )
              : file != null
                  ? Image.file(file!, fit: BoxFit.cover)
                  : Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textHint),
                    ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// ── "Add" tile ─────────────────────────────────────────────────────
class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  /// Pehli baar (koi certificate nahi) — poori chaudai ka bada tile,
  /// taaki worker ko saaf dikhe ki yahan kuch upload karna hai.
  final bool wide;

  const _AddTile({required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? double.infinity : 96,
        height: wide ? 96 : 96,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
            const SizedBox(height: 4),
            Text(
              wide ? 'add_certificate_hint'.tr : 'add_label'.tr,
              textAlign: TextAlign.center,
              style: KTextStyle.poppins(fs: 11, c: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
