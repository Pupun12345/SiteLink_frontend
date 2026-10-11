import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/config/app_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP UPDATE SERVICE — Firebase Remote Config se force / soft update
// ═══════════════════════════════════════════════════════════════════
// Play Store par nayi build jaate hi purane users ko update karwana hota
// hai. Backend deploy kiye bina ye control chahiye, isliye Firebase
// Remote Config — console me value badlo, sab clients tak pahunch jaati
// hai.
//
// Firebase Console → Remote Config me ye 4 parameters banao:
//
//   android_min_version   "1.2.0"   isse neeche = FORCE (band nahi kar sakte)
//   android_latest_version "1.4.0"  isse neeche = SOFT (Later dabaa sakte hain)
//   ios_min_version       "1.2.0"
//   ios_latest_version    "1.4.0"
//   update_message        "Naya version..."   (optional)
//
// ── Do zaroori design decisions ─────────────────────────────────────
//
// 1. FAIL-OPEN. Remote Config fetch fail ho, timeout ho, ya value galat
//    ho — hum user ko kabhi block nahi karte. Firebase ka ek outage poori
//    app ko brick kar de, isse bura kuch nahi. Shak ho to aage jaane do.
//
// 2. Version compare NUMBERS se, string se nahi. "1.10.0" < "1.9.0" hota
//    hai string compare me — yani 1.10.0 wala user force-update me phas
//    jaata. Har hissa int me compare karte hain.
class AppUpdateService extends GetxService {
  static AppUpdateService get to => Get.find<AppUpdateService>();

  static const _kAndroidMin = 'android_min_version';
  static const _kAndroidLatest = 'android_latest_version';
  static const _kIosMin = 'ios_min_version';
  static const _kIosLatest = 'ios_latest_version';
  static const _kMessage = 'update_message';

  FirebaseRemoteConfig? _rc;
  bool _dialogOpen = false;

  /// Soft update user ne is session me tal diya — dobara mat chidhao.
  bool _softDismissedThisSession = false;

  String _currentVersion = '';

  /// `main()` me Firebase init ke baad. Fail ho to chup-chaap nikal jao.
  Future<AppUpdateService> init() async {
    try {
      _currentVersion = (await PackageInfo.fromPlatform()).version;

      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Force-update ek emergency lever hai — 12 ghante purani value
        // se kaam nahi chalega. 15 min me nayi value aa jaati hai.
        minimumFetchInterval: const Duration(minutes: 15),
      ));
      // Defaults aise rakhe hain ki fetch fail hone par bhi koi block na ho.
      await rc.setDefaults(const {
        _kAndroidMin: '0.0.0',
        _kAndroidLatest: '0.0.0',
        _kIosMin: '0.0.0',
        _kIosLatest: '0.0.0',
        _kMessage: '',
      });
      await rc.fetchAndActivate();
      _rc = rc;
      if (kDebugMode) {
        debugPrint('[AppUpdate] current=$_currentVersion '
            'min=${_minVersion()} latest=${_latestVersion()}');
      }
    } catch (e) {
      debugPrint('[AppUpdate] init failed (fail-open): $e');
    }
    return this;
  }

  String _minVersion() =>
      _rc?.getString(Platform.isIOS ? _kIosMin : _kAndroidMin) ?? '0.0.0';

  String _latestVersion() =>
      _rc?.getString(Platform.isIOS ? _kIosLatest : _kAndroidLatest) ?? '0.0.0';

  /// Zaroorat ho to update dialog dikhao. App start aur resume par call hota
  /// hai. Kuch bhi गड़बड़ ho to kuch nahi dikhata (fail-open).
  Future<void> checkAndPrompt() async {
    if (_rc == null || _dialogOpen || _currentVersion.isEmpty) return;

    // Config purani ho sakti hai — resume par refresh, par fail ho to
    // cached value se hi kaam chala lo.
    try {
      await _rc!.fetchAndActivate();
    } catch (_) {/* cached value hi sahi */}

    final force = compareVersions(_currentVersion, _minVersion()) < 0;
    final soft = compareVersions(_currentVersion, _latestVersion()) < 0;

    if (!force && !soft) return;
    if (!force && _softDismissedThisSession) return;
    if (Get.context == null) return;

    _dialogOpen = true;
    await Get.dialog<void>(
      _UpdateDialog(
        force: force,
        message: _rc?.getString(_kMessage) ?? '',
        onUpdate: openStore,
        onLater: () {
          _softDismissedThisSession = true;
          Get.back();
        },
      ),
      // Force update me bahar tap karke band nahi kar sakte
      barrierDismissible: !force,
    );
    _dialogOpen = false;
  }

  Future<void> openStore() async {
    final url = Platform.isIOS ? AppConfig.appStoreUrl : AppConfig.playStoreUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdate] store open failed: $e');
    }
  }

  /// Semver compare: a < b → -1, a == b → 0, a > b → 1.
  ///
  /// Hissa-dar-hissa NUMBERS compare karta hai, isliye 1.10.0 > 1.9.0 sahi
  /// nikalta hai (string compare yahan ulta jawab deta hai). Alag lambai
  /// bhi chalti hai — "1.2" aur "1.2.0" barabar mane jaate hain.
  ///
  /// `static` + public taaki test likhna aasan rahe.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split('+')      // build number (1.2.0+45) hata do
        .first
        .trim()
        .split('.')
        .map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

    final pa = parts(a);
    final pb = parts(b);
    final len = pa.length > pb.length ? pa.length : pb.length;

    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  UPDATE WATCHER — dashboards ke around patla wrapper
// ═══════════════════════════════════════════════════════════════════
// App khulte hi check, aur background se wapas aane par dobara — taaki
// user ke app khole rehne ke dauraan release ho to bhi pakad me aaye.
class AppUpdateWatcher extends StatefulWidget {
  final Widget child;
  const AppUpdateWatcher({super.key, required this.child});

  @override
  State<AppUpdateWatcher> createState() => _AppUpdateWatcherState();
}

class _AppUpdateWatcherState extends State<AppUpdateWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (!Get.isRegistered<AppUpdateService>()) return;
    AppUpdateService.to.checkAndPrompt();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Dialog ─────────────────────────────────────────────────────────
class _UpdateDialog extends StatelessWidget {
  final bool force;
  final String message;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const _UpdateDialog({
    required this.force,
    required this.message,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    // Force update me back button bhi band — warna user dialog se nikal
    // ke purani build chalata rahega.
    return PopScope(
      canPop: !force,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                    force
                        ? Icons.system_update_rounded
                        : Icons.rocket_launch_rounded,
                    color: AppColors.primary,
                    size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                force ? 'update_required_title'.tr : 'update_available_title'.tr,
                style: KTextStyle.poppins(fs: 18, fw: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message.trim().isNotEmpty
                    ? message.trim()
                    : (force
                        ? 'update_required_body'.tr
                        : 'update_available_body'.tr),
                style: KTextStyle.poppins(fs: 13.5, c: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpdate,
                  child: Text('update_now_btn'.tr),
                ),
              ),
              // "Later" sirf soft update me — force me koi raasta nahi.
              if (!force) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onLater,
                    child: Text('update_later_btn'.tr,
                        style: KTextStyle.poppins(
                            fs: 13,
                            fw: FontWeight.w600,
                            c: AppColors.textSecondary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
