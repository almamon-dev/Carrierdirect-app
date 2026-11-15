import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Real-time GPS Speedometer showing current vehicle speed in km/h.
class NavLiveSpeedometer extends StatelessWidget {
  final double currentSpeedKmh;

  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);

  const NavLiveSpeedometer({super.key, required this.currentSpeedKmh});

  @override
  Widget build(BuildContext context) {
    final int liveSpeed = currentSpeedKmh.round();

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$liveSpeed',
            style: GoogleFonts.inter(
              color: slateDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'km/h',
            style: GoogleFonts.inter(
              color: slateMuted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
