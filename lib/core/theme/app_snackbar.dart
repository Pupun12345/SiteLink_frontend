import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP SNACKBAR — Unified snackbar for success/error/warning/info
// ═══════════════════════════════════════════════════════════════════

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show({
    required SnackbarType type,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackbarData = _getSnackbarData(type);

    Get.rawSnackbar(
      titleText: title != null
          ? Text(
              title,
              style: KTextStyle.poppins(
                fs: 14,
                fw: FontWeight.w600,
                c: snackbarData.textColor,
              ),
            )
          : const SizedBox.shrink(),
      messageText: Text(
        message,
        style: KTextStyle.poppins(
          fs: 13,
          c: snackbarData.textColor,
        ),
      ),
      backgroundColor: snackbarData.backgroundColor,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: AppDimens.radiusLg,
      margin: const EdgeInsets.all(AppDimens.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.down,
      icon: Icon(
        snackbarData.icon,
        color: snackbarData.textColor,
        size: 24,
      ),
      shouldIconPulse: false,
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
     // behavior: SnackBarBehavior.floating,
     // forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }

  /// Success snackbar
  static void success({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        type: SnackbarType.success,
        title: title ?? 'Success',
        message: message,
        duration: duration,
      );

  /// Error snackbar
  static void error({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        type: SnackbarType.error,
        title: title ?? 'Error',
        message: message,
        duration: duration,
      );

  /// Warning snackbar
  static void warning({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        type: SnackbarType.warning,
        title: title ?? 'Warning',
        message: message,
        duration: duration,
      );

  /// Info snackbar
  static void info({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(
        type: SnackbarType.info,
        title: title ?? 'Info',
        message: message,
        duration: duration,
      );

  /// Get snackbar styling data based on type
  static _SnackbarData _getSnackbarData(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarData(
          backgroundColor: AppColors.successLight,
          textColor: AppColors.success,
          icon: Icons.check_circle_rounded,
        );
      case SnackbarType.error:
        return _SnackbarData(
          backgroundColor: AppColors.errorLight,
          textColor: AppColors.error,
          icon: Icons.error_rounded,
        );
      case SnackbarType.warning:
        return _SnackbarData(
          backgroundColor: AppColors.warningLight,
          textColor: AppColors.warning,
          icon: Icons.warning_rounded,
        );
      case SnackbarType.info:
        return _SnackbarData(
          backgroundColor: AppColors.infoLight,
          textColor: AppColors.info,
          icon: Icons.info_rounded,
        );
    }
  }
}

class _SnackbarData {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  _SnackbarData({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });
}
