import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../shared/utils/app_toast.dart';

/// Modal sheet for searching amenities (Gas, Food, Parking, Restroom) along the navigation route.
class NavQuickSearchModal extends StatelessWidget {
  static const Color slateDark = Color(0xFF1E293B);

  const NavQuickSearchModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(4.0),
        ), // 4px border radius
      ),
      builder: (_) => const NavQuickSearchModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search Along Route',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: slateDark,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickSearchItem(
                  context,
                  Icons.local_gas_station_rounded,
                  'Gas',
                  const Color(0xFF2563EB),
                ),
                _buildQuickSearchItem(
                  context,
                  Icons.restaurant_rounded,
                  'Food',
                  const Color(0xFFF59E0B),
                ),
                _buildQuickSearchItem(
                  context,
                  Icons.local_parking_rounded,
                  'Parking',
                  const Color(0xFF16A34A),
                ),
                _buildQuickSearchItem(
                  context,
                  Icons.wc_rounded,
                  'Restroom',
                  const Color(0xFF9333EA),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        AppToast.info(context, 'Searching for nearby $label along route');
      },
      borderRadius: BorderRadius.circular(4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: slateDark,
            ),
          ),
        ],
      ),
    );
  }
}
