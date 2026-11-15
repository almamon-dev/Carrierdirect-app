import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../services/google_navigation_service.dart';

/// Top Turn-by-Turn Instruction Banner with dynamic distance, road name, and voice toggle.
class NavTopInstructionBanner extends StatelessWidget {
  final NavigationManeuver? currentManeuver;
  final NavigationManeuver? nextManeuver;
  final String displayDistance;
  final String displayInstruction;
  final String displayRoad;
  final bool isMuted;
  final VoidCallback onToggleMute;

  static const Color navDarkGreen = Color(0xFF0F5132);
  static const Color navSubGreen = Color(0xFF0B3D26);

  const NavTopInstructionBanner({
    super.key,
    required this.currentManeuver,
    required this.nextManeuver,
    required this.displayDistance,
    required this.displayInstruction,
    required this.displayRoad,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Maneuver Card (4px border radius)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: navDarkGreen,
            borderRadius: BorderRadius.circular(4.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Maneuver Arrow Icon (from Google)
              Icon(
                currentManeuver?.icon ?? Icons.navigation_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 14),

              // Dynamic Distance & Google Instruction
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayDistance,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          letterSpacing: -0.2,
                        ),
                        children: _buildInstructionSpans(
                          instruction: displayInstruction,
                          roadName: displayRoad,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Voice Mic Button
              GestureDetector(
                onTap: onToggleMute,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Secondary Sub-Banner: "Then ↰" (from Google next step)
        if (nextManeuver != null)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: navSubGreen,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Then',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(nextManeuver!.icon, color: Colors.white, size: 15),
              ],
            ),
          ),
      ],
    );
  }

  List<TextSpan> _buildInstructionSpans({
    required String instruction,
    required String roadName,
  }) {
    if (roadName.isNotEmpty &&
        instruction.toLowerCase().contains(roadName.toLowerCase())) {
      final lowerInst = instruction.toLowerCase();
      final lowerRoad = roadName.toLowerCase();
      final start = lowerInst.indexOf(lowerRoad);
      final prefix = instruction.substring(0, start);
      final exactRoad = instruction.substring(start, start + roadName.length);
      final suffix = instruction.substring(start + roadName.length);

      return [
        TextSpan(text: prefix),
        TextSpan(
          text: exactRoad,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 16.0,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        TextSpan(text: suffix),
      ];
    }
    return [TextSpan(text: instruction)];
  }
}
