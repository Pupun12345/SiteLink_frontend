import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  FRESHER / EXPERIENCED — do button ka chunav
// ═══════════════════════════════════════════════════════════════════
// Worker profile (registration + edit) aur vendor ka job post — teeno
// jagah yahi. "Fresher" = 0 saal experience (backend me experience "0"),
// isliye alag field ki zaroorat nahi; har jagah 0 ko "Fresher" dikhate hain.
class ExperienceLevelToggle extends StatelessWidget {
  final bool isFresher;
  final ValueChanged<bool> onChanged;
  /// Job post me label alag hota hai ("Fresher chalega" vs "Experienced").
  final String? fresherLabel;
  final String? experiencedLabel;

  const ExperienceLevelToggle({
    super.key,
    required this.isFresher,
    required this.onChanged,
    this.fresherLabel,
    this.experiencedLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(bool fresher, IconData icon, String label) {
      final selected = isFresher == fresher;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(fresher),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18,
                    color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: KTextStyle.poppins(
                          fs: 13,
                          fw: selected ? FontWeight.w700 : FontWeight.w500,
                          c: selected ? AppColors.primary : AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: [
      chip(true, Icons.school_outlined, fresherLabel ?? 'fresher_label'.tr),
      const SizedBox(width: 10),
      chip(false, Icons.work_history_outlined,
          experiencedLabel ?? 'experienced_label'.tr),
    ]);
  }
}

/// Saal ki ginti ko dikhane layak text: 0 → "Fresher", 1 → "1 yr", 3 → "3 yrs".
/// [raw] num ya String (backend experience String me rakhta hai).
String experienceText(Object? raw, {bool plus = false}) {
  final n = raw is num ? raw : num.tryParse(raw?.toString().trim() ?? '');
  if (n == null) return (raw?.toString().trim().isNotEmpty ?? false) ? raw.toString() : '—';
  if (n <= 0) return 'fresher_label'.tr;
  final v = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  return '$v${plus ? '+' : ''} ${n == 1 ? 'yr_singular'.tr : 'yr_plural'.tr}';
}
