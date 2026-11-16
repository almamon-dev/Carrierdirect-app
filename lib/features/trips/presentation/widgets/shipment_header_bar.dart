import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../screens/trips_screen.dart';

class ShipmentTopAppBar extends StatelessWidget {
  final ShipmentItem shipment;
  final VoidCallback onBack;

  static const Color darkSlate = AppColors.textPrimary;
  static const Color cardBorderColor = AppColors.border;

  const ShipmentTopAppBar({
    super.key,
    required this.shipment,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.only(right: 14.0),
              child: Icon(Icons.arrow_back, color: darkSlate, size: 22),
            ),
          ),
          const Expanded(
            child: Text(
              'Shipment Details',
              style: TextStyle(
                color: darkSlate,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ShipmentOrderHeaderCard extends StatelessWidget {
  final ShipmentItem shipment;
  final VoidCallback onCopyId;

  static const Color primaryOrange = AppColors.primary;
  static const Color darkSlate = AppColors.textPrimary;
  static const Color cardBorderColor = AppColors.border;

  const ShipmentOrderHeaderCard({
    super.key,
    required this.shipment,
    required this.onCopyId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onCopyId,
              child: Text(
                '#${shipment.id}',
                style: GoogleFonts.inter(
                  color: darkSlate,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  (shipment.isRelay &&
                          shipment.isLeg1 &&
                          shipment.isLeg1HandoverCompleted)
                      ? 'Leg 1 Completed'
                      : shipment.statusLabel,
                  style: GoogleFonts.inter(
                    color: AppColors.success,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShipmentTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<Map<String, dynamic>>? customTabs;

  static const Color primaryOrange = AppColors.primary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color cardBorderColor = AppColors.border;

  const ShipmentTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.customTabs,
  });

  @override
  Widget build(BuildContext context) {
    final tabs =
        customTabs ??
        [
          {'title': 'Overview', 'icon': Icons.description_outlined},
          {'title': 'Route', 'icon': Icons.location_on_rounded},
        ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
            ),
          ),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Row(
                children: List.generate(tabs.length, (index) {
                  final isSelected = selectedIndex == index;
                  final tab = tabs[index];
                  final badge = tab['badge'] as int?;

                  return Expanded(
                    child: InkWell(
                      onTap: () => onTabSelected(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tab['icon'] as IconData,
                              size: 17,
                              color: isSelected ? primaryOrange : textMuted,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              tab['title'] as String,
                              style: TextStyle(
                                color: isSelected ? primaryOrange : textMuted,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (badge != null && badge > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryOrange
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$badge',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : textMuted,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // WhatsApp full-width smooth sliding bottom indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: selectedIndex * tabWidth,
                bottom: 0,
                width: tabWidth,
                height: 3.0,
                child: Container(
                  color: primaryOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
