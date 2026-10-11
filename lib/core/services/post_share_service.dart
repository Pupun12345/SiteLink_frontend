import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/config/app_config.dart';
import '../models/community_feed_models.dart';
import '../theme/app_snackbar.dart';

// ═══════════════════════════════════════════════════════════════════
//  POST SHARE — feed ka share button
// ═══════════════════════════════════════════════════════════════════
// Link `http://<host>/p/<postId>` bhejte hain, `sitelink://` nahi —
// custom scheme WhatsApp/SMS me clickable hi nahi hota. http link
// backend ke landing page pe jaata hai jo app installed hone par app
// khol deta hai, warna Play Store.

/// Post ka native share sheet. [context] chahiye kyunki iPad par share
/// sheet ko anchor rect chahiye, warna crash hota hai.
Future<void> sharePost(BuildContext context, CommunityFeedModel post) async {
  final id = post.id?.trim() ?? '';
  if (id.isEmpty) {
    AppSnackbar.error(message: 'share_failed_error'.tr);
    return;
  }

  final url = AppConfig.postShareUrl(id);
  final by = (post.companyName?.trim().isNotEmpty ?? false)
      ? post.companyName!.trim()
      : (post.posterName?.trim() ?? '');

  // Content ka chhota sa hissa — poora paste karne se message bhara
  // bhara lagta hai aur link neeche dab jaata hai.
  final snippet = (post.content ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  final short = snippet.length > 120 ? '${snippet.substring(0, 119)}…' : snippet;

  final text = [
    if (by.isNotEmpty) '$by ${'shared_on_sitelink'.tr}',
    if (short.isNotEmpty) '"$short"',
    url,
  ].join('\n\n');

  await _share(context, text, 'shared_post_subject'.tr);
}

/// Job ka share — vendor apni posted job bhejta hai (log apply karein)
/// aur worker doosron ko bhejta hai. Link dono ke liye ek hi hai.
///
/// [jobId] backend ka asli job id hai (UI map me `apiId`), human-readable
/// `REQ-20E7` wala nahi.
Future<void> shareJob(
  BuildContext context, {
  required String? jobId,
  String? title,
  String? company,
  String? location,
  String? pay,
}) async {
  final id = jobId?.trim() ?? '';
  if (id.isEmpty) {
    AppSnackbar.error(message: 'share_failed_error'.tr);
    return;
  }

  final url = AppConfig.jobShareUrl(id);

  // Line by line — WhatsApp me chhoti lines zyada padhi jaati hain
  // bajaye ek lambe paragraph ke.
  final lines = <String>[
    if ((title ?? '').trim().isNotEmpty) '🔧 ${title!.trim()}',
    if ((company ?? '').trim().isNotEmpty) '🏢 ${company!.trim()}',
    if ((location ?? '').trim().isNotEmpty) '📍 ${location!.trim()}',
    if ((pay ?? '').trim().isNotEmpty) '💰 ${pay!.trim()}',
  ];

  final text = [
    if (lines.isEmpty) 'shared_job_fallback'.tr else lines.join('\n'),
    url,
  ].join('\n\n');

  await _share(context, text, 'shared_job_subject'.tr);
}

Future<void> _share(BuildContext context, String text, String subject) async {
  // iPad par share sheet ko anchor rect chahiye, warna crash hota hai.
  final box = context.findRenderObject() as RenderBox?;
  try {
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  } catch (_) {
    AppSnackbar.error(message: 'share_failed_error'.tr);
  }
}
