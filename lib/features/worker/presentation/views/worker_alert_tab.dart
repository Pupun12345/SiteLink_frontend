import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/custom_cirular_indicator.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

import '../controllers/worker_alerts_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER ALERTS TAB  —  Tab 2
// ═══════════════════════════════════════════════════════════════════
class WorkerAlertsTab extends StatelessWidget {
  const WorkerAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerAlertsController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: GradientAppBar(
        title: 'Alerts',
        showBack: false,
        actions: [
          TextButton(
            onPressed: ctrl.markAllRead,
            child: Text(
              'Mark all read',
              style: KTextStyle.poppins(fs: 12, c: Colors.white, fw: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CustomCircularIndicator());
          }
          if (ctrl.alerts.isEmpty) {
            return const _EmptyAlerts();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimens.lg),
            itemCount: ctrl.alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimens.sm),
            itemBuilder: (_, i) => _AlertCard(alert: ctrl.alerts[i]),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ALERT CARD
// ═══════════════════════════════════════════════════════════════════
class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color   = _resolveColor(alert.type);
    final icon    = _resolveIcon(alert.type);
    final timeAgo = _formatTime(alert.time);

    return Container(
      decoration: BoxDecoration(
        color: alert.isRead
            ? AppColors.surface
            : AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(
          color: alert.isRead ? AppColors.divider : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: KTextStyle.poppins(fs: 13, fw: FontWeight.w600),
                        ),
                      ),
                      Text(timeAgo, style: KTextStyle.poppins(fs: 10, c: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.subtitle,
                    style: KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!alert.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(AlertType t) {
    switch (t) {
      case AlertType.jobAssigned:    return Icons.work_rounded;
      case AlertType.jobCompleted:   return Icons.check_circle_rounded;
      case AlertType.newRequirement: return Icons.campaign_rounded;
      case AlertType.system:         return Icons.verified_rounded;
    }
  }

  Color _resolveColor(AlertType t) {
    switch (t) {
      case AlertType.jobAssigned:    return AppColors.primary;
      case AlertType.jobCompleted:   return AppColors.success;
      case AlertType.newRequirement: return AppColors.secondary;
      case AlertType.system:         return AppColors.info;
    }
  }

  String _formatTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24)   return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(Icons.notifications_off_outlined, size: 36, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 14),
        Text('No notifications', style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary)),
      ],
    ),
  );
}