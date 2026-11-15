import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppTextStyles {
  AppTextStyles._();

  // Page titles: 22–24px, weight 700
  static TextStyle pageTitle = AppTypography.pageTitle;

  // Section headings: 16–18px, weight 600
  static TextStyle sectionHeading = AppTypography.sectionHeading;

  // Card titles: 14–16px, weight 600
  static TextStyle cardTitle = AppTypography.cardTitle;

  // Body text: 14px, weight 400
  static TextStyle bodyText = AppTypography.bodyText;

  // Supporting metadata: 12px, weight 400
  static TextStyle metadata = AppTypography.metadata;

  // Buttons: 14px, weight 600
  static TextStyle button = AppTypography.button;

  // Backwards compatible aliases
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle h2 = AppTypography.pageTitle;
  static TextStyle h3 = AppTypography.sectionHeading;
  static TextStyle titleMedium = AppTypography.titleMedium;
  static TextStyle bodyLarge = AppTypography.bodyLarge;
  static TextStyle bodyMedium = AppTypography.bodyMedium;
  static TextStyle bodySmall = AppTypography.metadata;
  static TextStyle label = AppTypography.metadata.copyWith(
    fontWeight: FontWeight.w500,
  );
}
