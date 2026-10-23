import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'app/bindings/initial_binding.dart';
import 'app/firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/k_text_style.dart';
import 'core/i18n/app_translations.dart';
import 'core/services/auth_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/app_update_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Gallery ke liye Android ka system Photo Picker. Default me plugin bahar
  // ka Gallery app (MIUI Gallery / Google Photos) kholta hai — wo bhaari
  // hota hai aur kam RAM wale phone par Android hamara process maar deta
  // tha, wapas aane par app splash se restart hota (registration ka data
  // gayab). Photo Picker system ka halka UI hai, ye problem kam hoti hai.
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;

  await GetStorage.init();
  Get.put<LocaleService>(LocaleService(), permanent: true);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Google Sign-In ek baar initialize (v7 idempotent) ──────────────
  try {
    await AuthService.instance.init();
  } catch (e) {
    debugPrint('[main] AuthService init skipped: $e');
  }


  unawaited(NotificationService.instance.init().catchError((e) {
    debugPrint('[main] NotificationService init failed: $e');
  }));

  // Force/soft update — Firebase Remote Config se. Await NAHI karte:
  // Remote Config slow ya down ho to app ka launch nahi rukna chahiye.
  // Service khud fail-open hai; value aane par dashboard par dialog
  // dikh jaata hai (AppUpdateWatcher).
  Get.put<AppUpdateService>(AppUpdateService(), permanent: true);
  unawaited(AppUpdateService.to.init().catchError((e) {
    debugPrint('[main] AppUpdateService init failed: $e');
    return AppUpdateService.to;
  }));


  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const SiteLinkApp());

  // Deep links — runApp ke BAAD, taaki cold-start link aane par navigator
  // maujood ho. Fail ho to app normal chalti rahe.
  unawaited(DeepLinkService.instance.init().catchError((e) {
    debugPrint('[main] DeepLinkService init failed: $e');
  }));
}

class SiteLinkApp extends StatelessWidget {
  const SiteLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: GetMaterialApp(

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
        // Device ki system font-size (Settings → Display → Font size) badhane/
        // ghatane se app ka apna designed layout na tute — text scale ko
        // 0.9x–1.15x ke andar clamp karte hain (thoda accessibility ke liye
        // flex rakha hai, lekin extreme scale se overflow crash nahi hoga).
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.15,
              ),
            ),
            child: child!,
          );
        },
      ),
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
