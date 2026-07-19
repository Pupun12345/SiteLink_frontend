import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/k_text_style.dart';
import '../../../../core/theme/shared_widgets.dart';

// ═══════════════════════════════════════════════════════════════════
//  JOB APPLIED — SUCCESS / CELEBRATION SCREEN
// ═══════════════════════════════════════════════════════════════════
// Apply ke baad confetti + congratulations. ~4s baad auto-dismiss ho ke
// home jaata hai; "Back to Home" button se turant bhi ja sakte hain.
class JobAppliedSuccessView extends StatefulWidget {
  final String? jobTitle;
  const JobAppliedSuccessView({super.key, this.jobTitle});

  @override
  State<JobAppliedSuccessView> createState() => _JobAppliedSuccessViewState();
}

class _JobAppliedSuccessViewState extends State<JobAppliedSuccessView> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _confetti.play();
    // Kuch time baad auto-dismiss → home
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _goHome();
    });
  }

  void _goHome() {
    if (Get.currentRoute != AppRoutes.workerHome) {
      Get.offAllNamed(AppRoutes.workerHome);
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF1FF),
      body: Stack(
        children: [
          // ── Confetti (top-center se neeche girta hua) ───────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: pi / 2, // downward
              emissionFrequency: 0.06,
              numberOfParticles: 18,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                Colors.amber,
                Colors.deepPurple,
                Colors.orange,
                Colors.purpleAccent,
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Green check
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Application Submitted!',
                    textAlign: TextAlign.center,
                    style: KTextStyle.poppins(
                        fs: 24,
                        fw: FontWeight.bold,
                        c: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.jobTitle != null && widget.jobTitle!.isNotEmpty
                        ? 'Aapne "${widget.jobTitle}" ke liye apply kiya hai'
                        : 'Aapki application bhej di gayi hai',
                    textAlign: TextAlign.center,
                    style: KTextStyle.poppins(
                        fs: 14, c: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  // Congrats card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 26, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9E7FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Congratulations!',
                          style: KTextStyle.poppins(
                              fs: 16,
                              fw: FontWeight.w700,
                              c: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vendor jald hi aapse contact karega',
                          textAlign: TextAlign.center,
                          style: KTextStyle.poppins(
                              fs: 13, c: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        const Text('🎁', style: TextStyle(fontSize: 56)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  CustomButton(label: 'Back to Home', onTap: _goHome),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
