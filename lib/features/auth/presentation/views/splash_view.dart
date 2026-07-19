import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../controllers/splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _bottomFade;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Logo: chota se bada — "pop" feel ke liye easeOutBack (thoda overshoot).
    _logoScale = Tween(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    _logoFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeIn)),
    );

    // Bottom block (loader + powered-by) — logo settle hone ke baad fade+slide in.
    _bottomFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.55, 1.0, curve: Curves.easeIn)),
    );
    _bottomSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [

                // ── Center: Logo, animated scale + fade in ─────
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      'assets/images/app_logo_without_backgourd.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ── Bottom: Loading + Powered By ───────────────
                Positioned(
                  bottom: 36,
                  child: FadeTransition(
                    opacity: _bottomFade,
                    child: SlideTransition(
                      position: _bottomSlide,
                      child: Column(
                        children: [
                          Obx(() => controller.isLoading.value
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          )
                              : const SizedBox.shrink()),

                          const SizedBox(height: 12),

                          Text(
                            AppStrings.PoweredBySmartnexTechnology,
                            style: KTextStyle.poppins(
                              fs: 11,
                              c: Colors.black.withOpacity(0.35),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
