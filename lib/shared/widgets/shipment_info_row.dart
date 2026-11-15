import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class ShipmentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBoldValue;
  final Color? valueColor;
  final double labelWidth;

  const ShipmentInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isBoldValue = false,
    this.valueColor,
    this.labelWidth = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: GoogleFonts.inter(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: isBoldValue ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
