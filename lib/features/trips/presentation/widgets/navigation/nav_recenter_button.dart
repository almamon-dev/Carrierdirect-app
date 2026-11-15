import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Re-center navigation button shown when the driver pans the map away from current position.
class NavRecenterButton extends StatelessWidget {
  final VoidCallback onRecenter;

  static const Color navDarkGreen = Color(0xFF0F5132);
  static const Color slateDark = Color(0xFF1E293B);

  const NavRecenterButton({super.key, required this.onRecenter});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRecenter,
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0), // 4px border radius
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: 45 * (math.pi / 180),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: navDarkGreen,
                  size: 19,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Re-center',
                style: GoogleFonts.inter(
                  color: slateDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
