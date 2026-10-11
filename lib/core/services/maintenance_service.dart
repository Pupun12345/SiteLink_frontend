import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';
import '../models/app_config_models.dart';
import 'api_client.dart';

// ═══════════════════════════════════════════════════════════════════
//  MAINTENANCE SERVICE
// ═══════════════════════════════════════════════════════════════════
// Admin panel (Platform Settings → Maintenance Mode) se on hone par app ke
// dashboard par ek info dialog dikhta hai. Dialog dismissible hai — user
// "Got it" dabakar app normally use kar sakta hai.
//
// Dobara-dobara na chidhaye, isliye har notice sirf EK BAAR dikhta hai:
// dismiss karne par uska stamp (admin ka last update time) save ho jaata
// hai. Admin naya message set kare → stamp badalta hai → dialog phir dikhta
// hai.
class MaintenanceService extends GetxService {
  static MaintenanceService get to => Get.find<MaintenanceService>();

  static const _seenKey = 'maintenance_seen_stamp';

  final _storage = GetStorage();
  final _api = AppConfigApiService();

  /// Ek hi waqt me do dialog na khulein (dashboard + resume ek saath).
  bool _showing = false;

  /// Config fetch karo aur zaroorat ho to dialog dikhao.
  ///
  /// Worker/Vendor dono dashboards isse call karte hain. Network fail ho ya
  /// maintenance off ho — kuch nahi hota, app normal chalti hai.
  Future<void> checkAndShow() async {
    if (_showing) return;

    final info = await _api.getMaintenance();
    if (info == null || !info.enabled || info.message.trim().isEmpty) return;

    // Yehi notice user pehle dismiss kar chuka hai → dobara mat dikhao.
    if (info.stamp.isNotEmpty && _storage.read(_seenKey) == info.stamp) return;

    await _show(info);
  }

  Future<void> _show(MaintenanceInfo info) async {
    // Navigator abhi ready na ho (dashboard build ho raha ho) to agle frame
    // par dikhao.
    if (Get.context == null) return;

    _showing = true;
    await Get.dialog<void>(
      _MaintenanceDialog(info: info),
      barrierDismissible: true,
    );
    _showing = false;

    if (info.stamp.isNotEmpty) _storage.write(_seenKey, info.stamp);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAINTENANCE WATCHER — dashboards ke around ek patla wrapper
// ═══════════════════════════════════════════════════════════════════
// Dashboard khulte hi ek baar check karta hai, aur app background se wapas
// aane par dobara — taaki user ke app khole rehne ke dauraan admin
// maintenance on kare to bhi notice mil jaaye.
class MaintenanceWatcher extends StatefulWidget {
  final Widget child;
  const MaintenanceWatcher({super.key, required this.child});

  @override
  State<MaintenanceWatcher> createState() => _MaintenanceWatcherState();
}

class _MaintenanceWatcherState extends State<MaintenanceWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pehla frame ke baad — tab tak Get.context ready ho jaata hai.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  void _check() {
    if (!mounted) return;
    if (!Get.isRegistered<MaintenanceService>()) return;
    MaintenanceService.to.checkAndShow();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Dialog UI ──────────────────────────────────────────────────────
class _MaintenanceDialog extends StatelessWidget {
  final MaintenanceInfo info;
  const _MaintenanceDialog({required this.info});

  String? get _untilText {
    final u = info.until;
    if (u == null) return null;
    final local = u.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year}, $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final until = _untilText;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.build_rounded,
                  color: AppColors.warning, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              info.title.isNotEmpty ? info.title : 'maintenance_title'.tr,
              style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              info.message,
              style: KTextStyle.poppins(fs: 14, c: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (until != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMax),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    '${'maintenance_till'.tr} $until',
                    style: KTextStyle.poppins(
                        fs: 12, fw: FontWeight.w600, c: AppColors.warning),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('got_it_label'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
