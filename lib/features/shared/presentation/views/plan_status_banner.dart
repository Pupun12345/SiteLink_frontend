import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/models/plan_models.dart';
import 'plans_theme.dart';

// ═══════════════════════════════════════════════════════════════════
//  PLAN STATUS — "aapka plan active hai, kab tak hai" ka single source
// ═══════════════════════════════════════════════════════════════════
// Worker aur vendor dono Plans screens ke top par yahi banner lagta hai,
// taaki user ko plan kharidne se pehle hi pata ho ki uske paas already
// kya chal raha hai. Teen states:
//
//   active           → green, plan name + valid-till + days-left bar
//   active (≤7 din)  → amber, "renew soon" tone
//   expired          → red-ish, "expired on <date>", renew ka nudge
//
// Kuch bhi active na ho aur kabhi liya bhi na ho to banner dikhta hi
// nahi (naye user ki screen pehle jaisi saaf rehti hai).

const _greenBg     = Color(0xFFECFDF5);
const _greenBorder = Color(0xFFA7F3D0);
const _greenInk    = Color(0xFF047857);

const _amberBg     = Color(0xFFFFF7E6);
const _amberBorder = Color(0xFFFCD9A0);
const _amberInk    = Color(0xFF92620A);

const _redBg       = Color(0xFFFEF2F2);
const _redBorder   = Color(0xFFFECACA);
const _redInk      = Color(0xFFB91C1C);

String _fmtDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

/// Plans screen ke top ka status card. `sub` null/none ho to
/// `SizedBox.shrink()` return hota hai — call site par if lagane ki
/// zaroorat nahi.
class PlanStatusBanner extends StatelessWidget {
  final ActiveSubscription sub;

  /// Plan ka naam jo backend ne na diya ho to iske saath fallback
  /// (screen ka apna default label, e.g. "Worker Premium").
  final String? fallbackPlanName;

  /// Auto-pay chalu ho to banner ke andar "Cancel auto-payment" dikhta
  /// hai. Null hone par button nahi aata — user ke paas plan cancel
  /// karne ka rasta usi screen par hona chahiye jahan wo plan dekhta
  /// hai, isliye Plans screens ise zaroor pass karti hain.
  final Future<void> Function()? onCancelAutoPay;

  /// Cancel chal raha hai — button spinner dikhata hai aur dobara tap
  /// nahi hota (do cancel calls se Razorpay 400 deta hai).
  final bool cancelling;

  const PlanStatusBanner({
    super.key,
    required this.sub,
    this.fallbackPlanName,
    this.onCancelAutoPay,
    this.cancelling = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sub.active) return _activeCard();
    if (sub.isExpired) return _expiredCard();
    return const SizedBox.shrink();
  }

  String get _planName {
    final n = (sub.planName ?? '').trim();
    if (n.isNotEmpty) return n;
    return (fallbackPlanName ?? '').trim().isNotEmpty
        ? fallbackPlanName!.trim()
        : 'your_plan_fallback_name'.tr;
  }

  // ── Active (green) / expiring soon (amber) ────────────────────────
  Widget _activeCard() {
    final soon = sub.expiringSoon;
    final bg     = soon ? _amberBg : _greenBg;
    final border = soon ? _amberBorder : _greenBorder;
    final ink    = soon ? _amberInk : _greenInk;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                soon
                    ? Icons.error_outline_rounded
                    : Icons.verified_rounded,
                size: 18,
                color: ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  soon
                      ? 'plan_expiring_soon_title'.tr
                      : 'plan_active_title'.tr,
                  style: KTextStyle.poppins(
                      fs: 12,
                      fw: FontWeight.w700,
                      c: ink,
                      letterSpacing: 0.6),
                ),
              ),
              _daysPill(ink, border),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _planName,
            style: KTextStyle.poppins(
                fs: 18, fw: FontWeight.w800, c: PlansTheme.ink),
          ),
          const SizedBox(height: 4),
          Text(
            sub.expiresAt == null
                ? ''
                : 'plan_valid_till'
                    .trParams({'date': _fmtDate(sub.expiresAt!)}),
            style: KTextStyle.poppins(fs: 12.5, c: PlansTheme.grey),
          ),
          if (sub.startedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'plan_started_on'
                  .trParams({'date': _fmtDate(sub.startedAt!)}),
              style: KTextStyle.poppins(fs: 11, c: PlansTheme.grey),
            ),
          ],
          if (sub.startedAt != null && sub.expiresAt != null) ...[
            const SizedBox(height: 12),
            _progressBar(ink, border),
          ],
          if (soon) ...[
            const SizedBox(height: 10),
            Text(
              'plan_renew_hint'.tr,
              style: KTextStyle.poppins(fs: 11.5, c: ink, height: 1.4),
            ),
          ],
          if (sub.autoRenew) ...[
            const SizedBox(height: 12),
            _autoPayRow(ink, border),
          ],
        ],
      ),
    );
  }

  // ── Auto-payment ki line + cancel ─────────────────────────────────
  // Recurring charge ho raha hai to user ko ye साफ dikhna chahiye, aur
  // band karne ka rasta usi jagah hona chahiye — warna wo Razorpay ya
  // bank par jaake mandate dhoondhta hai.
  Widget _autoPayRow(Color ink, Color border) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.autorenew_rounded, size: 15, color: ink),
            const SizedBox(width: 7),
            // Expanded taaki lambi Hindi string overflow na kare.
            Expanded(
              child: Text(
                'autopay_on_note'.tr,
                style: KTextStyle.poppins(
                    fs: 11, fw: FontWeight.w600, c: ink, height: 1.35),
              ),
            ),
            if (onCancelAutoPay != null) ...[
              const SizedBox(width: 4),
              cancelling
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: onCancelAutoPay,
                      style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'autopay_cancel_btn'.tr,
                        style: KTextStyle.poppins(
                            fs: 11, fw: FontWeight.w700, c: _redInk),
                      ),
                    ),
            ],
          ],
        ),
      );

  /// "31 days left" pill.
  Widget _daysPill(Color ink, Color border) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          sub.daysRemaining == 1
              ? 'plan_days_left_one'.tr
              : 'plan_days_left'.trParams({'days': '${sub.daysRemaining}'}),
          style: KTextStyle.poppins(fs: 11, fw: FontWeight.w700, c: ink),
        ),
      );

  /// Kitna period bit chuka hai — pura term start→expiry ke against.
  Widget _progressBar(Color ink, Color border) {
    final total = sub.expiresAt!.difference(sub.startedAt!).inSeconds;
    final done = DateTime.now().difference(sub.startedAt!).inSeconds;
    // Clock skew ya same-second dates par NaN/overflow se bachao.
    final frac = total <= 0 ? 1.0 : (done / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: frac,
        minHeight: 6,
        backgroundColor: Colors.white,
        valueColor: AlwaysStoppedAnimation<Color>(ink),
      ),
    );
  }

  // ── Expired (red) ─────────────────────────────────────────────────
  Widget _expiredCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _redBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _redBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.history_toggle_off_rounded,
                size: 18, color: _redInk),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'plan_expired_title'.tr,
                    style: KTextStyle.poppins(
                        fs: 12,
                        fw: FontWeight.w700,
                        c: _redInk,
                        letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub.expiresAt == null
                        ? 'plan_expired_generic'.tr
                        : 'plan_expired_on'
                            .trParams({'date': _fmtDate(sub.expiresAt!)}),
                    style: KTextStyle.poppins(
                        fs: 12.5, c: PlansTheme.grey, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Paid feature ka lock chip — settings row ke trailing me.
///
/// Feature ko chhupate nahi hain: user ko pata rehna chahiye ki cheez
/// maujood hai, warna wo plan lene ki wajah hi nahi samajhta. Row tap
/// karne par Plans screen khulti hai.
class PlanLockChip extends StatelessWidget {
  const PlanLockChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: PlansTheme.amberSoft,
          borderRadius: BorderRadius.circular(AppDimens.radiusMax),
          border: Border.all(color: PlansTheme.amber.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 11, color: PlansTheme.amberDark),
            const SizedBox(width: 4),
            Text(
              'plan_locked_chip'.tr,
              style: KTextStyle.poppins(
                  fs: 9.5,
                  fw: FontWeight.w700,
                  c: PlansTheme.amberDark,
                  letterSpacing: 0.6),
            ),
          ],
        ),
      );
}

/// Plan card par lagne wala chhota "ACTIVE" badge — us card ke liye jo
/// abhi chal raha hai. `onDark` premium (navy) card ke liye.
class ActivePlanBadge extends StatelessWidget {
  final bool onDark;
  const ActivePlanBadge({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: onDark ? _greenInk : _greenBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: onDark ? _greenInk : _greenBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 11, color: onDark ? Colors.white : _greenInk),
            const SizedBox(width: 4),
            Text(
              'plan_active_badge'.tr,
              style: KTextStyle.poppins(
                fs: 9.5,
                fw: FontWeight.w700,
                c: onDark ? Colors.white : _greenInk,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
}
