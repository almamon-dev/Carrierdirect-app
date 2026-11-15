import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom Navigation Panel displaying ETA, distance, time, and navigation action controls.
class NavBottomPanel extends StatelessWidget {
  final String durationText;
  final String distanceText;
  final String etaClockText;
  final int alternativeCount;
  final VoidCallback onOpenTurnSteps;
  final VoidCallback onOpenRouteAlternatives;
  final VoidCallback onExitNavigation;

  static const Color etaGreen = Color(0xFF16A34A);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color blueNavigation = Color(0xFF2563EB);
  static const Color exitRed = Color(0xFFDC2626);

  const NavBottomPanel({
    super.key,
    required this.durationText,
    required this.distanceText,
    required this.etaClockText,
    required this.alternativeCount,
    required this.onOpenTurnSteps,
    required this.onOpenRouteAlternatives,
    required this.onExitNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(4.0),
        ), // 4px border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Expand Step List Button
                GestureDetector(
                  onTap: onOpenTurnSteps,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: slateDark,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Center: Dynamic ETA Time & Google Distance Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        durationText,
                        style: GoogleFonts.inter(
                          color: etaGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$distanceText • $etaClockText',
                        style: GoogleFonts.inter(
                          color: slateMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Alternative Route + Cancel/Exit Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onOpenRouteAlternatives,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Icon(
                              Icons.alt_route_rounded,
                              color: slateDark,
                              size: 19,
                            ),
                          ),
                          if (alternativeCount > 0)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: const BoxDecoration(
                                  color: blueNavigation,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$alternativeCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Red Exit Button
                    GestureDetector(
                      onTap: onExitNavigation,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: exitRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: exitRed.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
