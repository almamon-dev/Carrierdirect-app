import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class RouteTimeline extends StatelessWidget {
  final String originCity;
  final String originAddress;
  final String? originTime;
  final String destCity;
  final String destAddress;
  final String? destTime;
  final bool isCompact;

  const RouteTimeline({
    super.key,
    required this.originCity,
    required this.originAddress,
    this.originTime,
    required this.destCity,
    required this.destAddress,
    this.destTime,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Origin Stop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOriginPin(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          originCity,
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (originTime != null && originTime!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          originTime!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    originAddress,
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Vertical connecting line
        Padding(
          padding: const EdgeInsets.only(left: 8.25, top: 3, bottom: 3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: isCompact ? 14 : 20,
              width: 1.5,
              color: AppColors.border,
            ),
          ),
        ),

        // Destination Stop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDestinationPin(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destCity,
                          style: GoogleFonts.inter(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (destTime != null && destTime!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          destTime!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destAddress,
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOriginPin() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Icon(
          Icons.location_on_rounded,
          color: Color(0xFF16A34A), // Distinct Green for Pickup
          size: 18,
        ),
      ),
    );
  }

  Widget _buildDestinationPin() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Icon(
          Icons.location_on_rounded,
          color: Color(0xFFE53935), // Distinct Red for Destination
          size: 18,
        ),
      ),
    );
  }
}
