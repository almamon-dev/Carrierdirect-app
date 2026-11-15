import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final AppButtonVariant variant;
  final double? height;
  final double borderRadius;
  final double? fontSize;

  const AppButton({
    super.key,
    this.text,
    this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.height = 50.0,
    this.borderRadius = 4,
    this.fontSize,
  }) : assert(
         text != null || label != null,
         'Either text or label must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final isCompact = height != null && height! <= 38;
    final effectiveFontSize = fontSize ?? (isCompact ? 12.5 : 14.0);
    final effectiveIconSize = isCompact ? 15.0 : 18.0;

    final textStyle = GoogleFonts.inter(
      fontSize: effectiveFontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    final spinnerColor = variant == AppButtonVariant.primary
        ? Colors.white
        : AppColors.primary;

    Widget buttonContent = isLoading
        ? SizedBox(
            height: isCompact ? 16 : 20,
            width: isCompact ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: effectiveIconSize),
                SizedBox(width: isCompact ? 6 : 8),
              ],
              Text(text ?? label ?? '', style: textStyle),
            ],
          );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceMuted,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: AppColors.border, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: height, child: button);
    }

    return SizedBox(height: height, child: button);
  }
}
