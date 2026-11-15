import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../services/google_navigation_service.dart';

/// Modal bottom sheet allowing driver to preview and select alternative routes.
class NavRouteAlternativesModal extends StatelessWidget {
  final int selectedRouteIndex;
  final String primaryRouteSummary;
  final String primaryDurationText;
  final String primaryDistanceText;
  final List<AlternativeRouteInfo> alternativeRoutes;
  final ValueChanged<int> onSelectRoute;

  static const Color blueNavigation = Color(0xFF2563EB);
  static const Color slateDark = Color(0xFF1E293B);
  static const Color slateMuted = Color(0xFF64748B);

  const NavRouteAlternativesModal({
    super.key,
    required this.selectedRouteIndex,
    required this.primaryRouteSummary,
    required this.primaryDurationText,
    required this.primaryDistanceText,
    required this.alternativeRoutes,
    required this.onSelectRoute,
  });

  static void show(
    BuildContext context, {
    required int selectedRouteIndex,
    required String primaryRouteSummary,
    required String primaryDurationText,
    required String primaryDistanceText,
    required List<AlternativeRouteInfo> alternativeRoutes,
    required ValueChanged<int> onSelectRoute,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(4.0),
        ), // 4px border radius
      ),
      builder: (ctx) => NavRouteAlternativesModal(
        selectedRouteIndex: selectedRouteIndex,
        primaryRouteSummary: primaryRouteSummary,
        primaryDurationText: primaryDurationText,
        primaryDistanceText: primaryDistanceText,
        alternativeRoutes: alternativeRoutes,
        onSelectRoute: (idx) {
          Navigator.pop(ctx);
          onSelectRoute(idx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = <Map<String, dynamic>>[];
    options.add({
      'index': 0,
      'title': 'Fastest Route',
      'summary': primaryRouteSummary,
      'duration': primaryDurationText,
      'distance': primaryDistanceText,
      'badge': 'Fastest',
      'isFastest': true,
    });

    for (int i = 0; i < alternativeRoutes.length; i++) {
      final alt = alternativeRoutes[i];
      options.add({
        'index': i + 1,
        'title': 'Alternative ${i + 1}',
        'summary': alt.summary,
        'duration': Formatters.formatCompactDuration(alt.durationText),
        'distance': alt.distanceText,
        'badge': alt.differenceText,
        'isFastest': false,
      });
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.alt_route_rounded,
                      color: blueNavigation,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Route Alternatives',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: slateDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tap route to switch',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: slateMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...options.map((opt) {
              final int idx = opt['index'] as int;
              final bool isSelected = selectedRouteIndex == idx;
              final bool isFast = opt['isFastest'] as bool;

              return GestureDetector(
                onTap: () => onSelectRoute(idx),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(
                      4.0,
                    ), // 4px border radius
                    border: Border.all(
                      color: isSelected
                          ? blueNavigation
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? blueNavigation.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? blueNavigation
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFast ? Icons.bolt_rounded : Icons.alt_route_rounded,
                          size: 16,
                          color: isSelected ? Colors.white : slateMuted,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  opt['title'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? blueNavigation
                                        : slateDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFast
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    opt['badge'] as String,
                                    style: TextStyle(
                                      color: isFast
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF475569),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['summary'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: slateMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            opt['duration'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: slateDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            opt['distance'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: slateMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
