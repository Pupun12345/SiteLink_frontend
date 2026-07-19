import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../worker/presentation/views/worker_home_tab.dart';
import '../controllers/vendor_home_controller.dart';
import 'vendor_plans_view.dart';

// ═══════════════════════════════════════════════════════════════════
//  VENDOR HOME (COMMUNITY FEED)
// ═══════════════════════════════════════════════════════════════════
// Community feed worker aur vendor dono pe bilkul same hai (same
// /api/community APIs + WorkerFeedController). Isliye yahan wahi shared
// WorkerHomeTab reuse hota hai — koi alag hardcoded feed nahi.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkerHomeTab(
      // Notification bell → vendor ki Alerts tab (index 2)
      onNotificationTap: () => Get.find<VendorHomeController>().changeTab(2),
      // Subscription/Plan icon → vendor ka apna subscription page
      onPremiumTap: () => Get.to(() => const VendorPlansView()),
    );
  }
}
