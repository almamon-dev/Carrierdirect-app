import 'package:flutter/material.dart';

/// Central Design System Color Palette for CarrierDirect Driver App
/// Clean Minimal & Enterprise Logistics Design Tokens
class AppColors {
  AppColors._();

  // Primary Branding
  static const Color primary = Color(0xFFFF6A00); // Primary Orange
  static const Color primaryDark = Color(
    0xFFE85D04,
  ); // Primary Pressed / Darker Orange
  static const Color primaryLight = Color(
    0xFFFFF7ED,
  ); // Primary Light Tint (Orange-50)
  static const Color primaryOrange = Color(0xFFFF6A00);
  static const Color primaryOrangeDark = Color(0xFFE85D04);

  // Typography & Content Colors
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // Primary Text / Dark Navy (Slate-900)
  static const Color textSecondary = Color(
    0xFF64748B,
  ); // Secondary Text (Slate-500)
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Muted / Supporting Metadata (Slate-400)
  static const Color textNavy = Color(0xFF0F172A);
  static const Color textWhite = Colors.white;
  static const Color white = Colors.white;

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Background (Slate-50)
  static const Color surface = Color(0xFFFFFFFF); // Surface / Card (Pure White)
  static const Color surfaceMuted = Color(
    0xFFF1F5F9,
  ); // Muted Surface (Slate-100)
  static const Color card = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0F172A);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Border / Divider (Slate-200)
  static const Color borderSubtle = Color(
    0xFFF1F5F9,
  ); // Subtle Border (Slate-100)
  static const Color divider = Color(0xFFE2E8F0);

  // Status & Feedback Colors (Clean, accessible, readable)
  static const Color success = Color(0xFF16A34A); // Success Green (Green-600)
  static const Color successLight = Color(
    0xFFECFDF5,
  ); // Success Light (Green-50)
  static const Color successBorder = Color(
    0xFFA7F3D0,
  ); // Success Border (Green-200)

  static const Color info = Color(0xFF3B82F6); // Information Blue (Blue-500)
  static const Color infoLight = Color(0xFFEFF6FF); // Info Light (Blue-50)
  static const Color infoBorder = Color(0xFFBFDBFE); // Info Border (Blue-200)

  static const Color warning = Color(0xFFF59E0B); // Warning Amber (Amber-500)
  static const Color warningLight = Color(
    0xFFFFFBEB,
  ); // Warning Light (Amber-50)
  static const Color warningBorder = Color(
    0xFFFDE68A,
  ); // Warning Border (Amber-200)

  static const Color error = Color(0xFFEF4444); // Error Red (Red-500)
  static const Color errorLight = Color(0xFFFEF2F2); // Error Light (Red-50)
  static const Color errorBorder = Color(0xFFFECACA); // Error Border (Red-200)

  // Navigation & Interactive
  static const Color navInactive = Color(0xFF64748B);
  static const Color darkCard = Color(0xFF1E293B);
}
