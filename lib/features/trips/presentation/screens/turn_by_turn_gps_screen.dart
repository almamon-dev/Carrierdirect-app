import 'package:flutter/material.dart';
import '../../../../shared/utils/app_toast.dart';
import '../../../../shared/utils/map_launcher_helper.dart';
import 'trips_screen.dart';

class TurnByTurnGpsScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const TurnByTurnGpsScreen({
    super.key,
    required this.shipment,
  });

  @override
  State<TurnByTurnGpsScreen> createState() => _TurnByTurnGpsScreenState();
}

class _TurnByTurnGpsScreenState extends State<TurnByTurnGpsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isMuted = false;

  static const Color primaryGreen = Color(0xFF15803D);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: Stack(
        children: [
          // 1. Vector Map Simulation Canvas with Blue Route & City Grid
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _TurnByTurnMapPainter(pulseValue: _animController.value),
                );
              },
            ),
          ),

          // 2. Top Turn Navigation Banner (Deep Green)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Turn Arrow
                    const Icon(Icons.turn_right_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1.2 km',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Continue on Dhaka - Mymensingh Hwy (N3)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Voice Mic
                    GestureDetector(
                      onTap: () {
                        setState(() => _isMuted = !_isMuted);
                        AppToast.info(context, _isMuted ? 'Voice Directions Muted' : 'Voice Directions Active 🎙️');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Right Floating Map Controls
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 100,
              child: Column(
                children: [
                  _buildMapActionBtn(
                    icon: Icons.map_rounded,
                    onTap: () {
                      MapLauncherHelper.openGoogleMaps(
                        context,
                        destinationAddress: widget.shipment.destAddress,
                        destinationTitle: widget.shipment.destTitle,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMapActionBtn(
                    icon: Icons.search_rounded,
                    onTap: () => AppToast.info(context, 'Searching gas stations & stops along route...'),
                  ),
                  const SizedBox(height: 12),
                  _buildMapActionBtn(
                    icon: Icons.navigation_rounded,
                    onTap: () => AppToast.info(context, 'Re-centering navigation...'),
                  ),
                  const SizedBox(height: 12),
                  _buildMapActionBtn(
                    icon: Icons.settings_rounded,
                    onTap: () => AppToast.info(context, 'Route settings: Avoiding low clearances & tolls'),
                  ),
                ],
              ),
            ),

          // 4. Bottom Trip ETA & Red Exit Button Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ETA Info
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '35 min',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '21.4 km • 10:35 AM',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Red Exit Button
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0.5,
                      ),
                      child: const Text(
                        'Exit',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: const Color(0xFF334155), size: 20),
        ),
      ),
    );
  }
}

class _TurnByTurnMapPainter extends CustomPainter {
  final double pulseValue;

  _TurnByTurnMapPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Light Map Land
    final landPaint = Paint()..color = const Color(0xFFE8ECEF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // Green Parks / Water Body
    final waterPaint = Paint()..color = const Color(0xFFBAE6FD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.05, size.height * 0.2, 100, 70), const Radius.circular(16)),
      waterPaint,
    );

    final parkPaint = Paint()..color = const Color(0xFFDCFCE7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.02, size.height * 0.45, 90, 60), const Radius.circular(12)),
      parkPaint,
    );

    // 2. City Road Grid & Main Highway Avenues
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0;

    for (double x = 0; x < size.width; x += 55) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }
    for (double y = 0; y < size.height; y += 55) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }

    // Wide Main Avenues (Underneath Route)
    final mainAvenuePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 26.0
      ..strokeCap = StrokeCap.square;

    final roadX = size.width * 0.5;
    final turnY = size.height * 0.48;

    // North-South Avenue
    canvas.drawLine(Offset(roadX, 0), Offset(roadX, size.height), mainAvenuePaint);

    // East-West Highway Avenue
    final highwayPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..strokeWidth = 26.0
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(0, turnY), Offset(size.width, turnY), highwayPaint);

    // Road Center Dashed Dividers
    final centerDashPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(roadX, turnY), Offset(roadX, size.height), centerDashPaint);

    // 3. Active Navigation Blue Route Polyline (Strictly follows the road)
    final routePath = Path();
    routePath.moveTo(roadX, size.height);
    routePath.lineTo(roadX, turnY + 12);
    // Smooth turn curve onto highway
    routePath.quadraticBezierTo(roadX, turnY, roadX + 16, turnY);
    routePath.lineTo(size.width, turnY);

    final blueRoutePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(routePath, blueRoutePaint);

    // 4. Live GPS Arrow Head Position (Directly in center of road lane)
    final userPos = Offset(roadX, size.height * 0.72);

    // Blue Navigation Arrow Head Pin
    final circleBg = Paint()..color = Colors.white;
    canvas.drawCircle(userPos, 18, circleBg);
    final borderPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(userPos, 18, borderPaint);

    final arrowPaint = Paint()..color = const Color(0xFF2563EB);
    final arrowPath = Path()
      ..moveTo(userPos.dx, userPos.dy - 10)
      ..lineTo(userPos.dx + 8, userPos.dy + 8)
      ..lineTo(userPos.dx, userPos.dy + 4)
      ..lineTo(userPos.dx - 8, userPos.dy + 8)
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _TurnByTurnMapPainter oldDelegate) => true;
}
