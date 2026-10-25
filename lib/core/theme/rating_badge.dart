import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  RATING — Sitelink admin ki di hui worker rating
// ═══════════════════════════════════════════════════════════════════
// Rating SIRF admin deta hai (admin panel se), 1–5 ke beech, ek optional
// comment ke saath.
//
// Pehle ye job outcomes se automatically banti thi (vendor "completed /
// left early / no show" mark karta tha). Wo poora system hata diya gaya:
// kaam poora hua ya nahi, ye platform ka mamla nahi hai. Platform ka
// kaam yahin khatam — vendor ne job post ki, worker ne apply kiya, vendor
// ne confirm kiya.
//
// Ek soch-samajh kar liya gaya decision: rating na ho to "0.0 ★" NAHI
// dikhate. 0 ka matlab "kharaab kaam" nahi, "abhi rating mili hi nahi"
// hai — 0 stars dikhane se naya worker kabhi hire hi nahi hoga. Isliye
// backend `null` bhejta hai aur UI "Not rated yet" dikhata hai.
//
// NOTE: rating DOOSRON ko dikhna worker plan ka feature hai. Plan na ho
// to backend `null` bhejta hai, aur caller ko kuch dikhana hi nahi
// chahiye (dekho RatingPlanNudge).

/// Rating ke hisaab se rang — ek hi jagah taaki app bhar me consistent rahe.
Color ratingColor(num rating) {
  if (rating >= 4.5) return AppColors.success;
  if (rating >= 3.5) return AppColors.primary;
  if (rating >= 2.5) return AppColors.warning;
  return AppColors.error;
}

class RatingBadge extends StatelessWidget {
  /// Admin ki di hui rating (1–5). null/0 = abhi rating nahi mili.
  final num? rating;

  /// Chhota variant — list cards ke liye.
  final bool compact;

  const RatingBadge({
    super.key,
    required this.rating,
    this.compact = false,
  });

  bool get _hasRating => (rating ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    if (!_hasRating) return const _NotRatedChip();

    final value = rating!;
    final color = ratingColor(value);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 3),
          Text(
            value.toStringAsFixed(1),
            style: KTextStyle.poppins(
                fs: compact ? 11 : 12.5, fw: FontWeight.w700, c: color),
          ),
        ],
      ),
    );
  }
}

/// Abhi rating nahi mili. Neutral dikhta hai, kharaab nahi.
class _NotRatedChip extends StatelessWidget {
  const _NotRatedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.info),
          const SizedBox(width: 4),
          Text(
            'rating_not_rated'.tr,
            style: KTextStyle.poppins(
                fs: 10.5, fw: FontWeight.w600, c: AppColors.info),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BIG RATING CARD — worker ki apni profile ke liye
// ═══════════════════════════════════════════════════════════════════
class RatingSummaryCard extends StatelessWidget {
  /// Admin ki di hui rating (1–5). null = abhi nahi mili.
  final num? rating;

  /// Admin ka comment (optional).
  final String? comment;

  const RatingSummaryCard({
    super.key,
    required this.rating,
    this.comment,
  });

  bool get _hasRating => (rating ?? 0) > 0;

  String get _label {
    final r = rating!;
    if (r >= 4.5) return 'rating_excellent'.tr;
    if (r >= 4.0) return 'rating_very_good'.tr;
    if (r >= 3.0) return 'rating_good'.tr;
    if (r >= 2.0) return 'rating_fair'.tr;
    return 'rating_poor'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final color = _hasRating ? ratingColor(rating!) : AppColors.info;
    final note = (comment ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Score / not rated ──────────────────────────────
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _hasRating
                      ? Text(rating!.toStringAsFixed(1),
                          style: KTextStyle.poppins(
                              fs: 19, fw: FontWeight.w800, c: color))
                      : Icon(Icons.auto_awesome_rounded,
                          size: 24, color: color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasRating ? _label : 'rating_not_rated_title'.tr,
                      style: KTextStyle.poppins(fs: 14, fw: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // Dono case me batao ki rating kahan se aati hai —
                      // warna worker ko lagta hai wo khud kuch kar sakta
                      // hai, jabki ye Sitelink team deti hai.
                      _hasRating
                          ? 'rating_given_by_admin'.tr
                          : 'rating_not_rated_hint'.tr,
                      style: KTextStyle.poppins(
                          fs: 11.5, c: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Admin ka comment — rating ke saath aaye to dikhao, isse worker
          // ko pata chalta hai ki rating kis wajah se hai.
          if (_hasRating && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      size: 15, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(note,
                        style: KTextStyle.poppins(
                            fs: 12, c: AppColors.textSecondary, height: 1.45)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rating card ke neeche lagta hai jab plan na ho — batata hai ki rating
/// contractors ko tabhi dikhegi jab plan hoga.
///
/// Card ke andar na rakh kar alag rakha hai kyunki ye ek CTA hai (Plans
/// screen kholta hai), aur rating card khud sirf jaankari dikhata hai.
class RatingPlanNudge extends StatelessWidget {
  final VoidCallback onViewPlans;
  const RatingPlanNudge({super.key, required this.onViewPlans});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewPlans,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 17, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'rating_needs_plan_title'.tr,
                    style: KTextStyle.poppins(
                        fs: 12.5,
                        fw: FontWeight.w700,
                        c: AppColors.warning),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'rating_needs_plan_body'.tr,
                    style: KTextStyle.poppins(
                        fs: 11.5,
                        c: AppColors.textSecondary,
                        height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(
                      'view_plans_btn'.tr,
                      style: KTextStyle.poppins(
                          fs: 12,
                          fw: FontWeight.w700,
                          c: AppColors.warning),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: AppColors.warning),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
