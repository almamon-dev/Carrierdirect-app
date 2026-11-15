import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../services/google_navigation_service.dart';

/// Modal bottom sheet displaying step-by-step navigation maneuvers.
class NavTurnStepsModal extends StatelessWidget {
  final List<NavigationManeuver> maneuvers;
  final int currentManeuverIndex;
  final String durationText;
  final String distanceText;

  static const Color navDarkGreen = Color(0xFF0F5132);
  static const Color etaGreen = Color(0xFF16A34A);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);

  const NavTurnStepsModal({
    super.key,
    required this.maneuvers,
    required this.currentManeuverIndex,
    required this.durationText,
    required this.distanceText,
  });

  static void show(
    BuildContext context, {
    required List<NavigationManeuver> maneuvers,
    required int currentManeuverIndex,
    required String durationText,
    required String distanceText,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(4.0),
        ), // 4px border radius
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        expand: false,
        builder: (_, scrollCtrl) => NavTurnStepsModal(
          maneuvers: maneuvers,
          currentManeuverIndex: currentManeuverIndex,
          durationText: durationText,
          distanceText: distanceText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step-by-Step Directions',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: slateDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live Route: Pickup ➔ Delivery',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: slateMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(
                      4.0,
                    ), // 4px border radius
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    '$durationText • $distanceText',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: etaGreen,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                itemCount: maneuvers.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.only(left: 56),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                itemBuilder: (_, idx) {
                  final m = maneuvers[idx];
                  final isCurrent = idx == currentManeuverIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Step Icon Container (4px radius)
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? navDarkGreen
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(
                              4.0,
                            ), // 4px border radius
                            border: Border.all(
                              color: isCurrent
                                  ? navDarkGreen
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: navDarkGreen.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            m.icon,
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF334155),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Right: Distance, Instruction and Road detail
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.distanceText,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent
                                          ? navDarkGreen
                                          : slateDark,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'NEXT TURN',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF15803D),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.instruction,
                                style: GoogleFonts.inter(
                                  fontWeight: isCurrent
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 14.5,
                                  color: isCurrent
                                      ? slateDark
                                      : const Color(0xFF1E293B),
                                  height: 1.35,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (m.roadName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.alt_route_rounded,
                                      size: 13,
                                      color: slateMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        m.roadName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: slateMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
