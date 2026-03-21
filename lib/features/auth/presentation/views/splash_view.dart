import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/k_text_style.dart';
import '../controllers/splash_controller.dart';


class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SplashController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Brand Section ──────────────────────────────
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Logo circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: const Center(
                        child: _SitelinkLogoIcon(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App name
                    Text(
                      AppStrings.appName,
                      style: KTextStyle.poppins(fs: 32, fw: FontWeight.bold, c: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // Taglines
                    Text(
                      AppStrings.taglineHi,
                      style: KTextStyle.poppins(fs: 14, c: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.taglineEn,
                      style: KTextStyle.poppins(fs: 13, c: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),

                // ── Loading Footer ─────────────────────────────
                Positioned(
                  bottom: 48,
                  child: Column(
                    children: [
                      Obx(() => controller.isLoading.value
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox.shrink()),
                      const SizedBox(height: 8),
                      Text(
                        'Loading...',
                        style: KTextStyle.poppins(fs: 11, c: Colors.white.withOpacity(0.6), letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppStrings.poweredBy,
                        style: KTextStyle.poppins(fs: 10, c: Colors.white.withOpacity(0.5)),
                      ),
                    ],
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

class _SitelinkLogoIcon extends StatelessWidget {
  const _SitelinkLogoIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Location pin body
    paint.color = AppColors.primaryDark;
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.08);
    path.cubicTo(size.width * 0.25, size.height * 0.08, size.width * 0.08, size.height * 0.38,
        size.width * 0.08, size.height * 0.5);
    path.cubicTo(size.width * 0.08, size.height * 0.75, size.width * 0.5, size.height * 0.95,
        size.width * 0.5, size.height * 0.95);
    path.cubicTo(size.width * 0.5, size.height * 0.95, size.width * 0.92, size.height * 0.75,
        size.width * 0.92, size.height * 0.5);
    path.cubicTo(size.width * 0.92, size.height * 0.38, size.width * 0.75, size.height * 0.08,
        size.width * 0.5, size.height * 0.08);
    canvas.drawPath(path, paint);

    // Hard hat shape (white)
    paint.color = Colors.white;
    final hatPath = Path();
    hatPath.moveTo(size.width * 0.22, size.height * 0.52);
    hatPath.lineTo(size.width * 0.78, size.height * 0.52);
    hatPath.lineTo(size.width * 0.78, size.height * 0.58);
    hatPath.lineTo(size.width * 0.22, size.height * 0.58);
    hatPath.close();
    canvas.drawPath(hatPath, paint);

    final arcRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.52),
      width: size.width * 0.42,
      height: size.height * 0.32,
    );
    canvas.drawArc(arcRect, 3.14, 3.14, false, paint);

    // Center dot
    paint.color = AppColors.primaryDark;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.43), size.width * 0.06, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
