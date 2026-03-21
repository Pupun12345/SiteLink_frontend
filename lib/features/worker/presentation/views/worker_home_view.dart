import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sitelink/features/worker/presentation/views/work_profile_tab.dart';
import 'package:sitelink/features/worker/presentation/views/worker_alert_tab.dart';
import 'package:sitelink/features/worker/presentation/views/worker_my_job_tab.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Obx(() => _resolveTab(ctrl)),
      bottomNavigationBar: Obx(
            () => _WorkerBottomNav(
          current: ctrl.tabIndex.value,
          onTap: ctrl.changeTab,
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
        return WorkerHomeTab(homeCtrl: ctrl);
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

  static const _items = [
    (Icons.home_rounded,          Icons.home_outlined,             'Home'),
    (Icons.work_rounded,          Icons.work_outline_rounded,      'My Jobs'),
    (Icons.notifications_rounded, Icons.notifications_outlined,    'Alerts'),
    (Icons.person_rounded,        Icons.person_outline_rounded,    'Profile'),
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