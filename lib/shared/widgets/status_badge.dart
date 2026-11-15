import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

enum StatusType {
  active,
  scheduled,
  completed,
  cancelled,
  pending,
  assigned,
  verified,
  custom,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType? type;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.label,
    this.type,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  factory StatusBadge.fromStatus(
    String statusText, {
    IconData? icon,
    double fontSize = 11.5,
  }) {
    final s = statusText.toLowerCase();
    StatusType resolvedType = StatusType.active;

    if (s.contains('deliver') ||
        s.contains('complet') ||
        s.contains('verifi')) {
      resolvedType = StatusType.completed;
    } else if (s.contains('schedule') || s.contains('book')) {
      resolvedType = StatusType.scheduled;
    } else if (s.contains('cancel') || s.contains('fail')) {
      resolvedType = StatusType.cancelled;
    } else if (s.contains('pend') || s.contains('wait')) {
      resolvedType = StatusType.pending;
    } else if (s.contains('assign')) {
      resolvedType = StatusType.assigned;
    } else {
      resolvedType = StatusType.active;
    }

    return StatusBadge(
      label: statusText,
      type: resolvedType,
      icon: icon,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.infoLight;
    Color fg = textColor ?? AppColors.info;
    Color border = borderColor ?? AppColors.infoBorder;
    IconData? effectiveIcon = icon;

    if (type != null) {
      switch (type!) {
        case StatusType.active:
          bg = const Color(0xFFEFF6FF);
          fg = const Color(0xFF2563EB);
          border = const Color(0xFFDBEAFE);
          effectiveIcon ??= Icons.local_shipping_outlined;
          break;

        case StatusType.completed:
        case StatusType.verified:
          bg = const Color(0xFFECFDF5);
          fg = const Color(0xFF16A34A);
          border = const Color(0xFFA7F3D0);
          effectiveIcon ??= Icons.check_circle_outline_rounded;
          break;

        case StatusType.scheduled:
          bg = const Color(0xFFFFF7ED);
          fg = const Color(0xFFEA580C);
          border = const Color(0xFFFFEDD5);
          effectiveIcon ??= Icons.schedule_rounded;
          break;

        case StatusType.pending:
          bg = const Color(0xFFFFFBEB);
          fg = const Color(0xFFD97706);
          border = const Color(0xFFFDE68A);
          effectiveIcon ??= Icons.hourglass_empty_rounded;
          break;

        case StatusType.assigned:
          bg = const Color(0xFFF0FDF4);
          fg = const Color(0xFF15803D);
          border = const Color(0xFFBBF7D0);
          effectiveIcon ??= Icons.person_outline_rounded;
          break;

        case StatusType.cancelled:
          bg = const Color(0xFFFEF2F2);
          fg = const Color(0xFFDC2626);
          border = const Color(0xFFFECACA);
          effectiveIcon ??= Icons.cancel_outlined;
          break;

        case StatusType.custom:
          break;
      }
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (effectiveIcon != null) ...[
            Icon(effectiveIcon, size: fontSize + 1.5, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
