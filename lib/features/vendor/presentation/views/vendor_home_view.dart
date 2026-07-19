import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../shared/presentation/views/shared_views.dart';
import '../controllers/vendor_home_controller.dart';
import 'my_requests_view.dart';
import 'vendor_profile_screen.dart';
import 'home_view.dart';          // ✅ HomeView (was CommunityView)

// ═══════════════════════════════════════════════════════════════════
//  VENDOR HOME VIEW  — shell with bottom nav
// ═══════════════════════════════════════════════════════════════════

class VendorHomeView extends StatelessWidget {
  const VendorHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(VendorHomeController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Obx(() => _body(ctrl)),
      floatingActionButton: Obx(
            () =>  ctrl.tabIndex.value == 1
            ? FloatingActionButton.extended(
          onPressed: () => Get.toNamed(AppRoutes.newRequest),
          backgroundColor: AppColors.primary,
          elevation: 3,
          icon: const Icon(Icons.person_add_rounded,
              color: Colors.white),
          label: Text(
            AppStrings.NewRequest,
            style: KTextStyle.poppins(
                fs: 14, fw: FontWeight.w600, c: Colors.white),
          ),
        )
            : const SizedBox.shrink(),
      ),
      bottomNavigationBar: Obx(() => _BottomNav(
        current: ctrl.tabIndex.value,
        onTap: ctrl.changeTab,
      )),
    );
  }

  Widget _body(VendorHomeController ctrl) {
    switch (ctrl.tabIndex.value) {
      case 1:
        return const MyRequestsView();
      case 2:
        return const _NotificationsTab();
      case 3:
        return const _ProfileTab();
      default:
      // ✅ Tab 0 = HomeView (community feed IS the home now)
        return const HomeView();
    }
  }
}

// ── Placeholder Tabs ──────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();
  @override
  Widget build(BuildContext context) => const NotificationsView();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const VendorProfileScreen();
}

// ── Bottom Nav ─────────────────────────────────────────────────────
// 4 tabs now: Home | Requests | Alerts | Profile
// (Community tab removed — it IS home now)

class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.assignment_rounded, Icons.assignment_outlined, 'Requests'),
      (Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

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
            children: List.generate(items.length, (i) {
              final active = i == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? items[i].$1 : items[i].$2,
                        color: active
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$3,
                        style: KTextStyle.poppins(
                          fs: 10,
                          c: active
                              ? AppColors.primary
                              : AppColors.textHint,
                          fw: active
                              ? FontWeight.w600
                              : FontWeight.normal,
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