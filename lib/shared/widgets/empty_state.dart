import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.subtitle,
    this.actionLabel,
    this.onActionPressed,
    this.onAction,
    this.iconSize = 56.0,
  }) : assert(
         message != null || subtitle != null,
         'Either message or subtitle must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveMessage = message ?? subtitle ?? '';
    final effectiveOnAction = onActionPressed ?? onAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && effectiveOnAction != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: actionLabel!,
                onPressed: effectiveOnAction,
                isFullWidth: false,
                height: 42,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
