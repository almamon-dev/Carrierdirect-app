import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../chat/presentation/widgets/chat_channels_modal.dart';
import '../widgets/in_app_google_map_view.dart';
import 'shipment_details_screen.dart';
import 'shipment_status_screen.dart';
import 'trips_screen.dart';
import 'turn_by_turn_gps_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final ShipmentItem shipment;

  const LiveTrackingScreen({
    super.key,
    required this.shipment,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color primaryColor = AppColors.primary;
  static const Color lightBg = AppColors.background;
  static const Color cardBg = AppColors.surface;
  static const Color cardBorder = AppColors.border;
  static const Color textMuted = AppColors.textSecondary;
  static const Color textMain = AppColors.textPrimary;
  bool _showGoogleMap = true;

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
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textMain),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'GPS Navigation',
                    style: TextStyle(
                      color: textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Shortcut to timeline status
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShipmentStatusScreen(shipment: widget.shipment),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.timeline_rounded, size: 14, color: primaryColor),
                          SizedBox(width: 4),
                          Text('Timeline', style: TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: cardBorder, height: 1),

            // Main Content Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 1. Embedded Map Frame with Orange Curved Route & Stylized Vehicle
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B26),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            if (_showGoogleMap)
                              Positioned.fill(
                                child: InAppGoogleMapView(
                                  origin: LatLng(widget.shipment.originLat, widget.shipment.originLng),
                                  destination: LatLng(widget.shipment.destLat, widget.shipment.destLng),
                                  originTitle: widget.shipment.originTitle,
                                  destinationTitle: widget.shipment.destTitle,
                                ),
                              )
                            else
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _animController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: _LiveTrackingMapPainter(
                                        pulseValue: _animController.value,
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // Map Mode Toggle (Google Map / Stylized View)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: () => setState(() => _showGoogleMap = !_showGoogleMap),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_showGoogleMap ? Icons.map_rounded : Icons.radar_rounded, size: 14, color: const Color(0xFF0284C7)),
                                      const SizedBox(width: 5),
                                      Text(
                                        _showGoogleMap ? 'Google Map' : 'Vector Radar',
                                        style: const TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Quick full screen button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TurnByTurnGpsScreen(shipment: widget.shipment),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.fullscreen_rounded, color: textMain, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Bottom Shipment Overview Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ID and Status Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${widget.shipment.id}',
                                style: const TextStyle(
                                  color: textMain,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ShipmentStatusScreen(shipment: widget.shipment),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        widget.shipment.statusLabel,
                                        style: const TextStyle(
                                          color: primaryColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Route Origins
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${widget.shipment.originTitle} → ${widget.shipment.destTitle}',
                                  style: const TextStyle(
                                    color: textMain,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Distance and ETA
                          Row(
                            children: [
                              const Icon(Icons.navigation_outlined, color: Color(0xFF0284C7), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '25 min (${widget.shipment.distanceKm} km) away',
                                      style: const TextStyle(
                                        color: textMain,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    const Text(
                                      'via I-95 North',
                                      style: TextStyle(color: textMuted, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Primary Actions Row (Chat + Details + GPS)
                          Row(
                            children: [
                              // 1. Direct Chat with Parties Button
                              SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ChatChannelsModal.show(context, shipment: widget.shipment);
                                  },
                                  icon: const Icon(Icons.forum_outlined, size: 15, color: primaryColor),
                                  label: const Text('Chat', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryColor)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    side: const BorderSide(color: primaryColor, width: 1.2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. View Details Button
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ShipmentDetailsScreen(shipment: widget.shipment),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0.5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 3. Launch Turn-by-Turn Navigation
                              SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TurnByTurnGpsScreen(shipment: widget.shipment),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.navigation_rounded, size: 16),
                                  label: const Text('GPS', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white,
                                    elevation: 0.5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingMapPainter extends CustomPainter {
  final double pulseValue;

  _LiveTrackingMapPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Vector Map Background
    final bgPaint = Paint()..color = const Color(0xFF1E232E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // City street grid
    final gridPaint = Paint()
      ..color = const Color(0xFF2A3140)
      ..strokeWidth = 2.0;

    for (double x = 0; x < size.width; x += 35) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 35) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Curved Orange Highway Polyline matching Screenshot
    final routePath = Path();
    routePath.moveTo(size.width * 0.5, size.height * 0.85);
    routePath.lineTo(size.width * 0.5, size.height * 0.45);
    routePath.cubicTo(
      size.width * 0.5,
      size.height * 0.35,
      size.width * 0.72,
      size.height * 0.35,
      size.width * 0.65,
      size.height * 0.18,
    );
    routePath.cubicTo(
      size.width * 0.6,
      size.height * 0.08,
      size.width * 0.42,
      size.height * 0.12,
      size.width * 0.4,
      size.height * 0.04,
    );

    // 2. Wide Highway Road Corridor (Drawn underneath the route)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFF374151)
      ..strokeWidth = 26.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, roadBorderPaint);

    final roadAsphaltPaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 22.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(routePath, roadAsphaltPaint);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.25)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, glowPaint);

    // Orange Line
    final orangeLinePaint = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, orangeLinePaint);

    // Destination Pin
    final destPos = Offset(size.width * 0.4, size.height * 0.04);
    final pinPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawCircle(destPos, 5, pinPaint);

    // 3. Stylized Truck Icon Position matching screenshot
    final truckCenter = Offset(size.width * 0.5, size.height * 0.58);

    // Pulsing shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(truckCenter, 18 + (pulseValue * 12), shadowPaint);

    // Stylized Truck Body (Top-down view)
    final truckPaint = Paint()..color = const Color(0xFF1E2430);
    final truckBorder = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final truckRect = Rect.fromCenter(center: truckCenter, width: 22, height: 36);
    canvas.drawRRect(RRect.fromRectAndRadius(truckRect, const Radius.circular(5)), truckPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(truckRect, const Radius.circular(5)), truckBorder);

    // Windshield
    final windshieldPaint = Paint()..color = const Color(0xFF38BDF8);
    final windshieldRect = Rect.fromCenter(center: Offset(truckCenter.dx, truckCenter.dy - 8), width: 14, height: 6);
    canvas.drawRRect(RRect.fromRectAndRadius(windshieldRect, const Radius.circular(2)), windshieldPaint);
  }

  @override
  bool shouldRepaint(covariant _LiveTrackingMapPainter oldDelegate) => true;
}
