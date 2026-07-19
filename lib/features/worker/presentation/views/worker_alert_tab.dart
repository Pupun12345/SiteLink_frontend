import 'package:flutter/material.dart';
import '../../../shared/presentation/views/shared_views.dart';

// ═══════════════════════════════════════════════════════════════════
//  WORKER ALERTS TAB  —  Tab 2
// ═══════════════════════════════════════════════════════════════════
// Vendor aur worker dono ek hi NotificationsView + NotificationsController
// share karte hai (real /api/notifications data) — pehle yahan alag mock
// WorkerAlertsController tha.
class WorkerAlertsTab extends StatelessWidget {
  const WorkerAlertsTab({super.key});

  @override
  Widget build(BuildContext context) => const NotificationsView();
}
