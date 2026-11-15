import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Confirmation dialog before terminating active navigation.
class NavExitDialog {
  const NavExitDialog._();

  static const Color exitRed = Color(0xFFDC2626);
  static const Color blueNavigation = Color(0xFF2563EB);
  static const Color slateDark = Color(0xFF1E293B);

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ), // 4px border radius
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: exitRed, size: 24),
            const SizedBox(width: 8),
            Text(
              'Exit Navigation?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Stop active turn-by-turn navigation and return to shipment overview?',
          style: GoogleFonts.inter(fontSize: 14, color: slateDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Resume',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: blueNavigation,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: exitRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ), // 4px border radius
            ),
            child: const Text(
              'Exit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
