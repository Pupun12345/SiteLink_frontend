import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sitelink/features/worker/presentation/views/work_profile_tab.dart';
import 'package:sitelink/features/worker/presentation/views/worker_alert_tab.dart';
import 'package:sitelink/features/worker/presentation/views/worker_my_job_tab.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/services/app_update_service.dart';
import '../../../../core/services/maintenance_service.dart';
import '../controllers/worker_home_controller.dart';
import 'worker_home_tab.dart';


// ═══════════════════════════════════════════════════════════════════
//  WORKER HOME VIEW
//  Shell only — bottom nav + tab routing
//  Each tab owns its own file and controller
// ═══════════════════════════════════════════════════════════════════
class WorkerHomeView extends StatelessWidget {
  const WorkerHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(WorkerHomeController());

    // Admin ne maintenance mode on kiya ho to yahan info dialog dikhta hai
    return AppUpdateWatcher(
      // Force/soft update pehle — purani build par baaki kuch dikhane ka
      // matlab nahi.
      child: MaintenanceWatcher(
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Obx(() => _resolveTab(ctrl)),
        bottomNavigationBar: Obx(
              () => _WorkerBottomNav(
            current: ctrl.tabIndex.value,
            onTap: ctrl.changeTab,
          ),
        ),
      ),
      ),
    );
  }

  Widget _resolveTab(WorkerHomeController ctrl) {
    switch (ctrl.tabIndex.value) {
      case 1:
        return const WorkerMyJobsTab();
      case 2:
        return const WorkerAlertsTab();
      case 3:
        return const WorkerProfileTab();
      default:
        return WorkerHomeTab(onNotificationTap: () => ctrl.changeTab(2));
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BOTTOM NAV
// ═══════════════════════════════════════════════════════════════════
class _WorkerBottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _WorkerBottomNav({required this.current, required this.onTap});

  static List<(IconData, IconData, String)> get _items => [
    (Icons.home_rounded,          Icons.home_outlined,             'nav_home'.tr),
    (Icons.work_rounded,          Icons.work_outline_rounded,      'my_jobs'.tr),
    (Icons.notifications_rounded, Icons.notifications_outlined,    'notifications'.tr),
    (Icons.person_rounded,        Icons.person_outline_rounded,    'profile'.tr),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimens.bottomNavH,
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? _items[i].$1 : _items[i].$2,
                        color: active ? AppColors.primary : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[i].$3,
                        style: KTextStyle.poppins(
                          fs: 10,
                          c: active ? AppColors.primary : AppColors.textHint,
                          fw: active ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}