import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Floating right-side action column for Quick Search, Voice Mute, Compass, and Overview.
class NavFloatingActionColumn extends StatelessWidget {
  final bool isMuted;
  final bool isNorthUp;
  final double currentBearing;
  final bool isCameraTracking;
  final VoidCallback onSearch;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCompass;
  final VoidCallback onOverviewOrRecenter;

  static const Color slateDark = Color(0xFF1E293B);

  const NavFloatingActionColumn({
    super.key,
    required this.isMuted,
    required this.isNorthUp,
    required this.currentBearing,
    required this.isCameraTracking,
    required this.onSearch,
    required this.onToggleMute,
    required this.onToggleCompass,
    required this.onOverviewOrRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search along route
        _buildFloatingNavBtn(
          icon: Icons.search_rounded,
          tooltip: 'Search along route',
          onTap: onSearch,
        ),
        const SizedBox(height: 10),

        // 2. Speaker Volume (Voice Mute / Unmute)
        _buildFloatingNavBtn(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          tooltip: isMuted ? 'Unmute voice' : 'Mute voice',
          onTap: onToggleMute,
        ),
        const SizedBox(height: 10),

        // 3. Compass Needle (Toggles 3D vs North-Up)
        _buildCompassBtn(),
        const SizedBox(height: 10),

        // 4. Detour / Alternative Route Overview or Re-center
        _buildFloatingNavBtn(
          icon: isCameraTracking
              ? Icons.alt_route_rounded
              : Icons.navigation_rounded,
          tooltip: isCameraTracking
              ? 'Route overview & alternatives'
              : 'Re-center navigation',
          onTap: onOverviewOrRecenter,
        ),
      ],
    );
  }

  Widget _buildFloatingNavBtn({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: slateDark, size: 21)),
        ),
      ),
    );
  }

  Widget _buildCompassBtn() {
    return GestureDetector(
      onTap: onToggleCompass,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Transform.rotate(
            angle: isNorthUp ? 0.0 : -(currentBearing * (math.pi / 180.0)),
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _CompassNeedlePainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  const _CompassNeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Red North Needle
    final redPaint = Paint()..color = const Color(0xFFEF4444);
    final northPath = Path()
      ..moveTo(cx, 1)
      ..lineTo(cx + 4, cy)
      ..lineTo(cx - 4, cy)
      ..close();
    canvas.drawPath(northPath, redPaint);

    // Dark South Needle
    final southPaint = Paint()..color = const Color(0xFF94A3B8);
    final southPath = Path()
      ..moveTo(cx, size.height - 1)
      ..lineTo(cx + 4, cy)
      ..lineTo(cx - 4, cy)
      ..close();
    canvas.drawPath(southPath, southPaint);

    // Center pivot
    final pivotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), 2.5, pivotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
