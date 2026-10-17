import 'package:flutter/material.dart';

/// Central Design System Color Palette for CarrierDirect Driver App
class AppColors {
  AppColors._();

  // Primary Branding
  static const Color primary = Color(0xFFFF5500); // CarrierDirect Vibrant Orange
  static const Color primaryDark = Color(0xFFE04A00);
  static const Color primaryLight = Color(0xFFFFF0E8);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFE8FDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Crimson Alert
  static const Color info = Color(0xFF3B82F6); // Blue Accent

  // Background & Surface Colors
  static const Color background = Color(0xFFF8FAFC); // Clean Slate-50 Canvas
  static const Color backgroundDark = Color(0xFF0F172A); // Dark Slate Canvas
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color card = Colors.white;
  static const Color inputFill = Colors.white;

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate Header
  static const Color textSecondary = Color(0xFF64748B); // Slate Caption
  static const Color textMuted = Color(0xFF94A3B8); // Muted Disabled
  static const Color textWhite = Colors.white;
  static const Color white = Colors.white;

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Navigation & Interactive
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color darkCard = Color(0xFF1E293B);
}
