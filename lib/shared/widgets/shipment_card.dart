import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import 'route_timeline.dart';
import 'status_badge.dart';

class ShipmentCard extends StatelessWidget {
  final ShipmentItem shipment;
  final VoidCallback onTap;
  final VoidCallback? onGpsTap;
  final bool showActionButtons;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.onTap,
    this.onGpsTap,
    this.showActionButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInTransit = shipment.status == ShipmentFilter.inProgress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Order ID + Status Badge + Delivery Window
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${shipment.id}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatShortSchedule(
                                    shipment.deliveryDate,
                                    shipment.deliveryTime,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.fromStatus(shipment.statusLabel, fontSize: 11),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 14),

                // Vertical Route Timeline
                RouteTimeline(
                  originCity: shipment.originTitle,
                  originAddress: shipment.originAddress,
                  originTime: _formatShortSchedule(
                    shipment.pickupDate,
                    shipment.pickupTime,
                  ),
                  destCity: shipment.destTitle,
                  destAddress: shipment.destAddress,
                  destTime: _formatShortSchedule(
                    shipment.deliveryDate,
                    shipment.deliveryTime,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),

                // Bottom Metadata & Actions Row: Distance, Pallets/Weight, and GPS/Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Distance, Equipment & Weight tags
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildMetaTag(
                            icon: Icons.straighten_rounded,
                            label: shipment.formattedDistance,
                          ),
                          _buildMetaTag(
                            icon: Icons.layers_outlined,
                            label: shipment.palletQuantity,
                          ),
                          _buildMetaTag(
                            icon: Icons.fitness_center_rounded,
                            label: shipment.payloadWeight,
                          ),
                        ],
                      ),
                    ),

                    if (showActionButtons) ...[
                      const SizedBox(width: 8),
                      if (isInTransit && onGpsTap != null)
                        InkWell(
                          onTap: onGpsTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFFFFEDD5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.navigation_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTag({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatShortSchedule(String date, String time) {
    // 1. Remove 4-digit year like ' 2026' or ', 2026'
    String cleanDate = date.replaceAll(RegExp(r'[, ]+\d{4}'), '').trim();

    // 2. Format time window (e.g. '02:00 PM - 06:00 PM' -> '2:00 - 6:00 PM')
    String cleanTime = time.trim();
    final timeRangeRegex = RegExp(
      r'0?(\d{1,2}:\d{2})\s*(AM|PM)?\s*-\s*0?(\d{1,2}:\d{2})\s*(AM|PM)',
      caseSensitive: false,
    );
    final match = timeRangeRegex.firstMatch(cleanTime);
    if (match != null) {
      final startH = match.group(1);
      final startMeridiem = match.group(2);
      final endH = match.group(3);
      final endMeridiem = match.group(4);
      if (startMeridiem != null &&
          startMeridiem.toUpperCase() == endMeridiem?.toUpperCase()) {
        cleanTime = '$startH - $endH $endMeridiem';
      } else if (startMeridiem != null && endMeridiem != null) {
        cleanTime = '$startH $startMeridiem - $endH $endMeridiem';
      } else {
        cleanTime =
            '$startH - $endH${endMeridiem != null ? ' $endMeridiem' : ''}';
      }
    } else {
      cleanTime = cleanTime.replaceFirst(RegExp(r'^0(\d:)'), r'$1');
    }

    if (cleanDate.isNotEmpty && cleanTime.isNotEmpty) {
      return '$cleanDate • $cleanTime';
    } else if (cleanDate.isNotEmpty) {
      return cleanDate;
    } else if (cleanTime.isNotEmpty) {
      return cleanTime;
    }
    return 'Scheduled';
  }
}
