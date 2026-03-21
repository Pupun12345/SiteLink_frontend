import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════
//  INDICATOR STYLE
// ═══════════════════════════════════════════════════════════════════
enum IndicatorStyle { primary, secondary, white, grey }

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM CIRCULAR INDICATOR
// ═══════════════════════════════════════════════════════════════════
class CustomCircularIndicator extends StatelessWidget {
  final IndicatorStyle style;
  final double size;
  final double strokeWidth;

  const CustomCircularIndicator({
    super.key,
    this.style = IndicatorStyle.primary,
    this.size = 28.0,
    this.strokeWidth = 2.5,
  });

  Color get _color {
    switch (style) {
      case IndicatorStyle.primary:
        return AppColors.primary;
      case IndicatorStyle.secondary:
        return AppColors.secondary;
      case IndicatorStyle.white:
        return Colors.white;
      case IndicatorStyle.grey:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: _color,
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}