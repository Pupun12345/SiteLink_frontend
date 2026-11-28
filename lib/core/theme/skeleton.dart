import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  SKELETON / SHIMMER — data aane tak screen ka dhaancha
// ═══════════════════════════════════════════════════════════════════
// Pehle kai screens API ka jawab aane se pehle default / nakli data
// dikhati thi ("0 posts", "Not rated", "₹299", "Verification pending")
// jo baad me badal jaata tha — user ko galat lagta tha. Ab data aane
// tak yahi chamakta dhaancha dikhta hai.

const _base = Color(0xFFECEEF1);
const _highlight = Color(0xFFF8F9FB);

/// Bachchon ko ek saath chamkao.
class Skeleton extends StatelessWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: _base,
        highlightColor: _highlight,
        period: const Duration(milliseconds: 1200),
        child: child,
      );
}

/// Ek bhara hua dabba (photo, button, card ka hissa).
class SkBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkBox({super.key, this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// Text ki ek line.
class SkLine extends StatelessWidget {
  final double width;
  final double height;
  const SkLine({super.key, this.width = double.infinity, this.height = 12});

  @override
  Widget build(BuildContext context) =>
      SkBox(width: width, height: height, radius: 6);
}

class SkCircle extends StatelessWidget {
  final double size;
  const SkCircle({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      );
}

/// Ek card: avatar + 2-3 lines (feed post, job, notification, applicant).
class SkListCard extends StatelessWidget {
  final bool avatar;
  final bool media;
  const SkListCard({super.key, this.avatar = true, this.media = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.md),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (avatar) ...[const SkCircle(size: 42), const SizedBox(width: 12)],
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkLine(width: 140, height: 13),
              SizedBox(height: 8),
              SkLine(width: 90, height: 10),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        const SkLine(height: 11),
        const SizedBox(height: 8),
        const SkLine(width: 220, height: 11),
        if (media) ...[
          const SizedBox(height: 12),
          const SkBox(height: 170, radius: 10),
        ],
      ]),
    );
  }
}

/// Poori list ka shimmer (feed, jobs, notifications, applicants...).
class SkeletonList extends StatelessWidget {
  final int count;
  final bool avatar;
  final bool media;
  final EdgeInsets padding;
  const SkeletonList({
    super.key,
    this.count = 5,
    this.avatar = true,
    this.media = false,
    this.padding = const EdgeInsets.all(AppDimens.lg),
  });

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.scaffoldBg,
        child: Skeleton(
          child: ListView.builder(
            padding: padding,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            itemBuilder: (_, i) =>
                SkListCard(avatar: avatar, media: media && i.isEven),
          ),
        ),
      );
}

/// Profile / detail page: bada header + kuch cards.
class SkeletonPage extends StatelessWidget {
  final bool header;
  final int cards;
  const SkeletonPage({super.key, this.header = true, this.cards = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.scaffoldBg,
      child: Skeleton(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.lg),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            if (header) ...[
              const Center(child: SkCircle(size: 84)),
              const SizedBox(height: 14),
              const Center(child: SkLine(width: 160, height: 16)),
              const SizedBox(height: 10),
              const Center(child: SkLine(width: 110, height: 12)),
              const SizedBox(height: 22),
              Row(children: const [
                Expanded(child: SkBox(height: 56)),
                SizedBox(width: 10),
                Expanded(child: SkBox(height: 56)),
                SizedBox(width: 10),
                Expanded(child: SkBox(height: 56)),
              ]),
              const SizedBox(height: 18),
            ],
            for (int i = 0; i < cards; i++) ...[
              const SkBox(height: 110, radius: 14),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// Data laana fail hua — shimmer ki jagah ye (warna shimmer kabhi rukta
/// nahi aur user ko lagta hai app atak gaya).
class LoadErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const LoadErrorView({super.key, required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded,
              size: 44, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            message ?? 'network_error_retry'.tr,
            textAlign: TextAlign.center,
            style: KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('retry_label'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Plans screen: badge, headline, price, feature cards, button.
class PlansSkeleton extends StatelessWidget {
  final int cards;
  const PlansSkeleton({super.key, this.cards = 3});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const Center(child: SkBox(width: 170, height: 26, radius: 20)),
          const SizedBox(height: 16),
          const Center(child: SkBox(width: 120, height: 24, radius: 6)),
          const SizedBox(height: 18),
          const Center(child: SkLine(width: 260, height: 22)),
          const SizedBox(height: 10),
          const Center(child: SkLine(width: 200, height: 22)),
          const SizedBox(height: 14),
          const Center(child: SkLine(width: 240, height: 11)),
          const SizedBox(height: 20),
          const Center(child: SkLine(width: 130, height: 34)),
          const SizedBox(height: 24),
          for (int i = 0; i < cards; i++) ...[
            const SkBox(height: 92, radius: 14),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const SkBox(height: 52, radius: 14),
        ],
      ),
    );
  }
}
