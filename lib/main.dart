import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/bindings/initial_binding.dart';
import 'app/firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/k_text_style.dart';
import 'core/i18n/app_translations.dart';
import 'core/services/auth_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Local storage (token/session) — reads se pehle init zaroori ──────
  await GetStorage.init();

  // ── Locale service — GetMaterialApp `locale` read se pehle available ──
  Get.put<LocaleService>(LocaleService(), permanent: true);

  // ── Firebase — Google auth ke liye must (pehle missing tha) ─────────
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Google Sign-In ek baar initialize (v7 idempotent) ──────────────
  try {
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('[main] AuthService init skipped: $e');
  }

  // ── Push notifications — permission, listeners, background handler ──
  // Fire-and-forget: requestPermission()/getInitialMessage() OS dialog ke
  // response ka wait kar sakte hai — agar isse await karte to runApp() hi
  // kabhi na chalta (bas startup logs dikhte rehte, UI kabhi na aata).
  // (Token resync for an already-logged-in user happens in SplashController,
  // once InitialBinding has registered SessionService/RestApi.)
  unawaited(NotificationService.instance.init().catchError((e) {
    debugPrint('[main] NotificationService init failed: $e');
  }));

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,       // ✅ iOS — black icons
    ),
  );
  runApp(const SiteLinkApp());
}

class SiteLinkApp extends StatelessWidget {
  const SiteLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.SiteLink,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      translations: AppTranslations(),
      locale: LocaleService.to.currentLocale,
      fallbackLocale: const Locale('en', 'US'),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.scaffoldBg,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        surfaceTintColor: AppColors.surface,
      ),
      textTheme: TextTheme(
        bodyLarge:   KTextStyle.poppins(fs: 15, c: AppColors.textPrimary),
        bodyMedium:  KTextStyle.poppins(fs: 13, c: AppColors.textSecondary),
        bodySmall:   KTextStyle.poppins(fs: 12, c: AppColors.textSecondary),
        titleLarge:  KTextStyle.poppins(fs: 20, fw: FontWeight.w600, c: AppColors.textPrimary),
        titleMedium: KTextStyle.poppins(fs: 16, fw: FontWeight.w600, c: AppColors.textPrimary),
        titleSmall:  KTextStyle.poppins(fs: 14, fw: FontWeight.w500, c: AppColors.textPrimary),
        labelLarge:  KTextStyle.poppins(fs: 15, fw: FontWeight.w600, c: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size.fromHeight(52),
          textStyle: KTextStyle.poppins(fs: 15, fw: FontWeight.w600),
          shadowColor: Colors.black.withOpacity(0.08),
          elevation: 2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: KTextStyle.poppins(fs: 15, fw: FontWeight.w600),
        ),
      ),
   cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
    ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withOpacity(0.12),
        secondarySelectedColor: AppColors.primary,
        labelStyle: KTextStyle.poppins(fs: 12, c: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.textPrimary.withOpacity(0.92),
        contentTextStyle: KTextStyle.poppins(fs: 13, c: AppColors.surface),
      ),
    );
  }
}
