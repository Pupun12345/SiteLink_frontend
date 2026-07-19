import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/k_text_style.dart';

// ═══════════════════════════════════════════════════════════════════
//  CUSTOM BUTTON  — gradient primary / outlined secondary
// ═══════════════════════════════════════════════════════════════════
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double height;
  final double borderRadius;
  final Widget? leading;

  const CustomButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height = AppDimens.buttonHeight,
    this.borderRadius = AppDimens.radiusLg,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              // Outlined button ka background halka hota hai — white spinner
              // usme dikhta hi nahi, isliye outlined pe primary color.
              color: isOutlined ? AppColors.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(label, style: KTextStyle.poppins(fs: 15, fw: FontWeight.w600, c: isOutlined ? AppColors.primary : Colors.white)),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
            foregroundColor: AppColors.primary,
            textStyle: KTextStyle.poppins(fs: 15, fw: FontWeight.w600, c: AppColors.primary),
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
        ),
        child: content,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SITELINK TEXT FIELD
// ═══════════════════════════════════════════════════════════════════
class SitelinkTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Widget? prefix; // custom leading widget (e.g. +91 box) — prefixIcon ko override karta hai
  final Widget? suffix;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final bool isOptional;
  final bool showLabel;

  const SitelinkTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.isOptional = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            children: [
              Text(label, style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: AppColors.textSecondary)),
              if (isOptional) ...[
                const SizedBox(width: 4),
                Text('(Optional)', style: KTextStyle.poppins(fs: 11, c: AppColors.textHint)),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          style: KTextStyle.poppins(fs: 14, c: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: KTextStyle.poppins(fs: 13, c: AppColors.textHint),
            errorText: errorText,
            prefixIcon: prefix ??
                (prefixIcon != null
                    ? Icon(prefixIcon, color: AppColors.primary, size: AppDimens.iconMd)
                    : null),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF3F7FB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS BADGE
// ═══════════════════════════════════════════════════════════════════
enum BadgeType { pending, active, fulfilled, replaced, verified, rejected, completed }

class StatusBadge extends StatelessWidget {
  final BadgeType type;
  final String? customLabel;

  const StatusBadge({super.key, required this.type, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final data = _data();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: data.$1,
        borderRadius: BorderRadius.circular(AppDimens.radiusMax),
      ),
      child: Text(
        customLabel ?? data.$3,
        style: KTextStyle.poppins(fs: 11, fw: FontWeight.bold, c: data.$2),
      ),
    );
  }

  (Color, Color, String) _data() {
    switch (type) {
      case BadgeType.pending:    return (AppColors.warningLight,  AppColors.warning, 'Pending');
      case BadgeType.active:     return (AppColors.successLight,  AppColors.success, 'Active');
      case BadgeType.fulfilled:  return (AppColors.infoLight,     AppColors.info,    'Fulfilled');
      case BadgeType.replaced:   return (AppColors.errorLight,    AppColors.error,   'Replaced');
      case BadgeType.verified:   return (AppColors.successLight,  AppColors.success, '✓ Verified');
      case BadgeType.rejected:   return (AppColors.errorLight,    AppColors.error,   'Rejected');
      case BadgeType.completed:  return (AppColors.infoLight,     AppColors.info,    'Completed');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  APP CARD — white card with optional left accent border
// ═══════════════════════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  final Widget child;
  final bool showLeftBorder;
  final Color leftBorderColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showShadow;   // false = flat card (border ke saath, elevation nahi)
  final Color? borderColor; // showShadow:false ke waqt outline color

  const AppCard({
    super.key,
    required this.child,
    this.showLeftBorder = false,
    this.leftBorderColor = AppColors.primary,
    this.padding,
    this.borderRadius = AppDimens.radiusLg,
    this.onTap,
    this.showShadow = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow ? AppColors.cardShadow : null,
        border: _resolveBorder(),
      ),
      padding: padding ?? const EdgeInsets.all(AppDimens.cardPadding),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Border? _resolveBorder() {
    final flatSide = !showShadow
        ? BorderSide(color: borderColor ?? AppColors.divider)
        : BorderSide.none;
    if (showLeftBorder) {
      return Border(
        left: BorderSide(color: leftBorderColor, width: 4),
        top: flatSide,
        right: flatSide,
        bottom: flatSide,
      );
    }
    return showShadow ? null : Border.all(color: borderColor ?? AppColors.divider);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GRADIENT APP BAR
// ═══════════════════════════════════════════════════════════════════
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.75), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppDimens.appBarHeight,
          child: Row(
            children: [
              if (showBack)
                leading ??
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    )
              else
                leading ?? const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: KTextStyle.poppins(fs: 18, fw: FontWeight.w600, c: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SKILL CHIP
// ═══════════════════════════════════════════════════════════════════
class SkillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const SkillChip({super.key, required this.label, this.selected = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMax),
          border: Border.all(color: selected ? AppColors.primary.withOpacity(0.28) : AppColors.border),
        ),
        child: Text(
          label,
          style: KTextStyle.poppins(fs: 12, fw: FontWeight.w500, c: selected ? AppColors.primary : AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION HEADER ROW
// ═══════════════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: KTextStyle.poppins(fs: 14, fw: FontWeight.w600)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: KTextStyle.poppins(fs: 13, fw: FontWeight.w500, c: AppColors.primary)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SEGMENTED CONTROL
// ═══════════════════════════════════════════════════════════════════
class AppSegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onChanged;

  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected ? AppColors.cardShadow : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  options[i],
                  style: KTextStyle.poppins(
                    fs: 13,
                    fw: selected ? FontWeight.w600 : FontWeight.normal,
                    c: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  INFO BANNER — orange tinted info strip
// ═══════════════════════════════════════════════════════════════════
class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? bgColor;
  final Color? textColor;

  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border(left: BorderSide(color: textColor ?? AppColors.primary.withOpacity(0.5), width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor ?? AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: KTextStyle.poppins(fs: 12, c: textColor ?? AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AVATAR CIRCLE — initials or icon
// ═══════════════════════════════════════════════════════════════════
class AvatarCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bgColor;
  final double fontSize;
  final String? imageUrl; // diya to network image, warna initials fallback

  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = AppDimens.avatarMd,
    this.bgColor,
    this.fontSize = 16,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').isNotEmpty;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsText(),
            )
          : _initialsText(),
    );
  }

  Widget _initialsText() => Center(
        child: Text(
          initials.toUpperCase(),
          style: KTextStyle.poppins(
              fs: fontSize, fw: FontWeight.bold, c: Colors.white),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  COUNTER WIDGET (+/- buttons)
// ═══════════════════════════════════════════════════════════════════
class CounterWidget extends StatelessWidget {
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int max;

  const CounterWidget({
    super.key,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    this.min = 1,
    this.max = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(Icons.remove, value > min ? onDecrement : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: KTextStyle.poppins(fs: 16, fw: FontWeight.bold, c: AppColors.primary)),
        ),
        _btn(Icons.add, value < max ? onIncrement : null),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? cb) {
    return GestureDetector(
      onTap: cb,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cb != null ? AppColors.selectionBg : AppColors.divider,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cb != null ? AppColors.primary : AppColors.border),
        ),
        child: Icon(icon, size: 18, color: cb != null ? AppColors.primary : AppColors.textHint),
      ),
    );
  }
}
