import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Photorealistic Google Map blurred snapshot skeleton placeholder.
/// Renders an authentic blurred map background (waterways, highways, street networks,
/// green terrain patches, and polyline route corridors) with an animated diagonal
/// shimmer light-sweep, frosted floating cards, and map controls.
/// Provides a rich, image-like blurred map look without any spinners or loading text.
class MapSkeletonPlaceholder extends StatefulWidget {
  const MapSkeletonPlaceholder({super.key});

  @override
  State<MapSkeletonPlaceholder> createState() => _MapSkeletonPlaceholderState();
}

class _MapSkeletonPlaceholderState extends State<MapSkeletonPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildShimmerBar({
    required double width,
    required double height,
    double val = 0.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
          stops: [
            (val - 0.35).clamp(0.0, 1.0),
            val.clamp(0.0, 1.0),
            (val + 0.35).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        final val = _shimmerAnimation.value;
        return Stack(
          children: [
            // 1. Photorealistic Blurred Map Background (Simulated Google Maps Imagery)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 5.5,
                  sigmaY: 5.5,
                  tileMode: TileMode.decal,
                ),
                child: CustomPaint(
                  painter: _RealisticBlurredMapPainter(),
                ),
              ),
            ),

            // 2. Soft Frosted Tint to enhance the modern blurred image effect
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),

            // 3. Animated Diagonal Shimmer Light-Sweep
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: [
                      (val - 0.35).clamp(0.0, 1.0),
                      val.clamp(0.0, 1.0),
                      (val + 0.35).clamp(0.0, 1.0),
                    ],
                  ),
                ),
              ),
            ),

            // 4. Top-Left Floating Order Summary Card Skeleton (5px radius)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E000000),
                      blurRadius: 5,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShimmerBar(width: 82, height: 9, val: val),
                    const SizedBox(height: 4),
                    _buildShimmerBar(width: 110, height: 7, val: val),
                    const SizedBox(height: 3),
                    _buildShimmerBar(width: 98, height: 7, val: val),
                  ],
                ),
              ),
            ),

            // 5. Top-Right Map Controls Skeleton (5px radius buttons)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 28,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(5.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6. Subtle Google Map Watermark at Bottom-Left
            Positioned(
              bottom: 6,
              left: 8,
              child: Text(
                'Google',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.22),
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RealisticBlurredMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Google Maps Base Landmass
    final bgPaint = Paint()..color = const Color(0xFFE8ECE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Natural Greenery / Park Areas (Organic Google Maps Green Blobs)
    final parkPaint = Paint()
      ..color = const Color(0xFFCCE8CE)
      ..style = PaintingStyle.fill;

    // Park patch 1: Top-Right
    final park1 = Path()
      ..moveTo(size.width * 0.65, 0)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.15,
        size.width * 0.90,
        size.height * 0.20,
        size.width,
        size.height * 0.12,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(park1, parkPaint);

    // Park patch 2: Bottom-Left
    final park2 = Path()
      ..moveTo(0, size.height * 0.60)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.62,
        size.width * 0.22,
        size.height * 0.82,
        0,
        size.height * 0.90,
      )
      ..close();
    canvas.drawPath(park2, parkPaint);

    // Park patch 3: Center-East
    final park3 = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.62),
        width: size.width * 0.35,
        height: size.height * 0.22,
      ));
    canvas.drawPath(park3, parkPaint);

    // 3. Water Features / Rivers (Google Maps Blue)
    final riverPaint = Paint()
      ..color = const Color(0xFFA5D8FF)
      ..strokeWidth = 22.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mainRiver = Path()
      ..moveTo(0, size.height * 0.38)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.30,
        size.width * 0.48,
        size.height * 0.68,
        size.width,
        size.height * 0.60,
      );
    canvas.drawPath(mainRiver, riverPaint);

    // Tributary river branch
    final tributaryPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final tributary = Path()
      ..moveTo(size.width * 0.36, size.height * 0.42)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.15,
        size.width * 0.55,
        size.height * 0.05,
        size.width * 0.62,
        0,
      );
    canvas.drawPath(tributary, tributaryPaint);

    // 4. Urban Street Grid (Crisp white roads)
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (double y = 20; y < size.height; y += 38) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    for (double x = 20; x < size.width; x += 45) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // Diagonal local avenues
    canvas.drawLine(
      Offset(0, size.height * 0.2),
      Offset(size.width * 0.8, size.height),
      streetPaint..strokeWidth = 3.0,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width, size.height * 0.7),
      streetPaint..strokeWidth = 3.0,
    );

    // 5. Major Highways (Google Maps Amber/Gold Corridors)
    final highwayCasing = Paint()
      ..color = const Color(0xFFFDE68A)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayCore = Paint()
      ..color = const Color(0xFFFEF3C7)
      ..strokeWidth = 4.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final hwy1 = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.72,
        size.width * 0.45,
        size.height * 0.28,
        size.width,
        size.height * 0.20,
      );
    canvas.drawPath(hwy1, highwayCasing);
    canvas.drawPath(hwy1, highwayCore);

    final hwy2 = Path()
      ..moveTo(size.width * 0.20, 0)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.65,
        size.height * 0.60,
        size.width * 0.90,
        size.height,
      );
    canvas.drawPath(hwy2, highwayCasing);
    canvas.drawPath(hwy2, highwayCore);

    // 6. Navigation Route Corridors (Google Maps Blue & Emerald Green)
    // Leg 1: Driver -> Pickup (Google Blue corridor)
    final leg1Route = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leg1Path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.58)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.54,
        size.width * 0.38,
        size.height * 0.44,
        size.width * 0.52,
        size.height * 0.38,
      );
    canvas.drawPath(leg1Path, leg1Route);

    // Leg 2: Pickup -> Delivery (Google Emerald Green corridor)
    final leg2Route = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leg2Path = Path()
      ..moveTo(size.width * 0.52, size.height * 0.38)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.42,
        size.width * 0.72,
        size.height * 0.58,
        size.width * 0.58,
        size.height * 0.74,
      );
    canvas.drawPath(leg2Path, leg2Route);

    // 7. Location Markers (Driver halo, Pickup dot, Delivery pin)
    // Driver halo
    final driverCenter = Offset(size.width * 0.22, size.height * 0.58);
    canvas.drawCircle(
      driverCenter,
      12.0,
      Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      driverCenter,
      6.0,
      Paint()..color = const Color(0xFF2563EB),
    );
    canvas.drawCircle(
      driverCenter,
      2.5,
      Paint()..color = Colors.white,
    );

    // Pickup green pin
    final pickupCenter = Offset(size.width * 0.52, size.height * 0.38);
    canvas.drawCircle(
      pickupCenter,
      7.0,
      Paint()..color = const Color(0xFF16A34A),
    );
    canvas.drawCircle(
      pickupCenter,
      7.0,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Delivery red pin
    final destCenter = Offset(size.width * 0.58, size.height * 0.74);
    canvas.drawCircle(
      destCenter,
      7.0,
      Paint()..color = const Color(0xFFEF4444),
    );
    canvas.drawCircle(
      destCenter,
      7.0,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
