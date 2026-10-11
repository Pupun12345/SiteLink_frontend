import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';
import '../models/job_models.dart';

// ═══════════════════════════════════════════════════════════════════
//  JOB ROLES — "2 × Welder, 1 × Mason, 3 × Helper" theek se dikhana
// ═══════════════════════════════════════════════════════════════════
// Pehle ye info job ke title me ghus jaati thi ("Welder +3 more
// Required") aur asli breakdown description ke free text me dab jaata
// tha. Ab backend structured `roles` bhejta hai, aur worker/vendor dono
// screens yahi widgets use karti hain — ek jagah se consistent.
//
// Purani jobs me `roles` khaali hai; tab ye widgets kuch render nahi
// karte aur caller ka purana title/description hi dikhta hai.

/// Job card ke liye compact ek-line summary — "3 roles · 6 workers".
/// Roles khaali ho to `null`, taaki caller row hi skip kar de.
String? jobRolesSummary(List<JobRole> roles) {
  if (roles.isEmpty) return null;
  final total = roles.fold<int>(0, (sum, r) => sum + r.quantity);
  if (roles.length == 1) {
    return 'workers_needed_suffix'.trParams({'count': '$total'});
  }
  return 'roles_and_workers_summary'
      .trParams({'roles': '${roles.length}', 'workers': '$total'});
}

/// Roles ko chips me — job card par. `maxVisible` se aage "+N" chip.
class JobRoleChips extends StatelessWidget {
  final List<JobRole> roles;

  /// Card par jagah kam hoti hai; baaki ke liye ek "+N" chip.
  final int maxVisible;

  const JobRoleChips({super.key, required this.roles, this.maxVisible = 3});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    final visible = roles.take(maxVisible).toList();
    final hidden = roles.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final r in visible) _chip(r.label),
        // Chhupe roles ki ginti — poori list detail screen par dikhti hai.
        if (hidden > 0)
          _chip('plus_n_more'.trParams({'count': '$hidden'}), muted: true),
      ],
    );
  }

  Widget _chip(String text, {bool muted = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: muted
              ? AppColors.scaffoldBg
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimens.radiusMax),
          border: Border.all(
            color: muted
                ? AppColors.divider
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          text,
          style: KTextStyle.poppins(
            fs: 11,
            fw: muted ? FontWeight.normal : FontWeight.w600,
            c: muted ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
      );
}

/// Detail screen ke liye poori list — har role apni row me count ke saath.
/// Yahan kuch chhupaya nahi jaata.
class JobRolesBreakdown extends StatelessWidget {
  final List<JobRole> roles;
  const JobRolesBreakdown({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();
    final total = roles.fold<int>(0, (sum, r) => sum + r.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < roles.length; i++) ...[
          if (i > 0) const Divider(height: 14, color: AppColors.divider),
          Row(
            children: [
              const Icon(Icons.engineering_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  roles[i].skill,
                  style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                ),
                child: Text(
                  'x_workers'.trParams({'count': '${roles[i].quantity}'}),
                  style: KTextStyle.poppins(
                      fs: 11, fw: FontWeight.w700, c: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
        // Total tabhi jab ek se zyada role ho — ek role par ye repeat hi hai.
        if (roles.length > 1) ...[
          const Divider(height: 16, color: AppColors.divider),
          Row(
            children: [
              Expanded(
                child: Text('total_workers_label'.tr,
                    style: KTextStyle.poppins(
                        fs: 12, c: AppColors.textSecondary)),
              ),
              Text('$total',
                  style: KTextStyle.poppins(
                      fs: 14, fw: FontWeight.w800, c: AppColors.textPrimary)),
            ],
          ),
        ],
      ],
    );
  }
}
