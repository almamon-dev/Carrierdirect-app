import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/routes/app_routes.dart';
import '../../services/notification_service.dart';

/// Screen 3: Notification Permission (Stay Updated)
/// Perfectly Proportioned Layout matching Reference Mockup with balanced spacing throughout
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _proceedToDashboard() {
    if (!mounted) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  void _handleEnableNotifications() async {
    setState(() => _isLoading = true);
    try {
      await _notificationService.requestPermissions();
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
      _proceedToDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    // Responsive Hero banner taking ~38% of screen height
    final heroHeight = (screenHeight * 0.38).clamp(220.0, 340.0);
    final bottomInset =
        mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom : 8.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Top Section: High-Res Sunset Highway Truck Photo with CarrierDirect Logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sunset Truck Photo Background
                Image.asset(
                  'assets/images/splash_bg.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.2, -0.25),
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/login-bg.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.2, -0.25),
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Vignette Overlay for High-Contrast Status Bar & Logo
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // CarrierDirect Logo Centered at Top inside SafeArea
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildCarrierDirectLogo(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. White Bottom Sheet extending down to the very edge of screen
          Positioned(
            top: heroHeight - 32,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Overlapping Bell Badge with White Ring & Soundwaves
                  Positioned(
                    top: -38,
                    child: _buildOverlappingBellBadge(),
                  ),

                  // Sheet Body Content with Natural, Proportional Spacing
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        46,
                        18,
                        bottomInset + 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title: "Stay Updated"
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              children: [
                                TextSpan(text: 'Stay '),
                                TextSpan(
                                  text: 'Updated',
                                  style: TextStyle(
                                    color: Color(0xFFFF4500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Subtitle
                          const Text(
                            'Get real-time load alerts, order updates\nand important messages from dispatch.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 1. New load alerts
                          _buildFeatureCard(
                            iconWidget: const Icon(
                              Icons.notifications_rounded,
                              color: Color(0xFFFF5722),
                              size: 22,
                            ),
                            title: 'New load alerts',
                            subtitle:
                                'Get notified when new loads match your route.',
                          ),

                          // 2. Order status updates (3D Isometric Shipping Box)
                          _buildFeatureCard(
                            iconWidget: const _IsometricBoxIcon(),
                            title: 'Order status updates',
                            subtitle:
                                'Track pickup, in-transit and delivery status.',
                          ),

                          // 3. Messages from dispatch (Speech Bubble with 3 Dots)
                          _buildFeatureCard(
                            iconWidget: const _ChatBubbleWithDots(),
                            title: 'Messages from dispatch',
                            subtitle:
                                'Receive important messages instantly.',
                          ),

                          // 4. Delivery confirmations (Orange Circle Badge with White Checkmark)
                          _buildFeatureCard(
                            iconWidget: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                            title: 'Delivery confirmations',
                            subtitle:
                                'Get notified when deliveries are completed.',
                          ),

                          const SizedBox(height: 18),

                          // Primary Action: "Enable Notifications"
                          _buildEnableButton(),

                          const SizedBox(height: 10),

                          // Secondary Action: "Not Now" Hyperlink (clean text link)
                          _buildNotNowLink(),

                          // Footer 5px spacing
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CarrierDirect Logo with Brand Name
  Widget _buildCarrierDirectLogo() {
    return Image.asset(
      'assets/images/Logo.png',
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(24, 20),
            painter: const _CarrierSwooshPainter(),
          ),
          const SizedBox(width: 5),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              children: [
                TextSpan(
                  text: 'Carrier',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Direct',
                  style: TextStyle(color: Color(0xFFFF5722)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Overlapping Circular Bell Badge with White Ring & Soundwaves
  Widget _buildOverlappingBellBadge() {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 Radiating Soundwave Rays (Top-Left of Bell)
          CustomPaint(
            size: const Size(92, 92),
            painter: const _BellRaysPainter(),
          ),

          // Outer White Ring with Shadow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF5E2B),
                    Color(0xFFFF3D00),
                  ],
                ),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Feature Card with Peach Squircle, Title, Subtitle, and Chevron
  Widget _buildFeatureCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Soft Peach Icon Container
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EB),
              borderRadius: BorderRadius.circular(5.0),
            ),
            alignment: Alignment.center,
            child: iconWidget,
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Grey Chevron
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 19,
          ),
        ],
      ),
    );
  }

  /// Primary Orange Gradient Action Button with Bell on Left and Right Arrow on Right
  Widget _buildEnableButton() {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFF5722),
            Color(0xFFFF3D00),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleEnableNotifications,
          borderRadius: BorderRadius.circular(5.0),
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    ),
                  )
                : Row(
                    children: const [
                      Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Enable Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Secondary "Not Now" Hyperlink (Clean text link, no container button)
  Widget _buildNotNowLink() {
    return GestureDetector(
      onTap: _proceedToDashboard,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Text(
          'Not Now',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}

/// Custom Painter for 3 Orange Soundwave Rays radiating on the top-left of the Bell Badge
class _BellRaysPainter extends CustomPainter {
  const _BellRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    // Three rays radiating to the top-left
    final angles = [-2.40, -2.80, -3.20]; // in radians
    const innerRadius = 38.0;
    const rayLength = 8.0;

    for (final angle in angles) {
      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (innerRadius + rayLength) * math.cos(angle),
        center.dy + (innerRadius + rayLength) * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Isometric 3D Shipping Box Icon (Order status updates)
class _IsometricBoxIcon extends StatelessWidget {
  const _IsometricBoxIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: CustomPaint(
        painter: const _IsometricBoxPainter(),
      ),
    );
  }
}

class _IsometricBoxPainter extends CustomPainter {
  const _IsometricBoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top face
    final topFace = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.92, h * 0.30)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.08, h * 0.30)
      ..close();
    canvas.drawPath(
      topFace,
      Paint()..color = const Color(0xFFFF8A65),
    );

    // Left face
    final leftFace = Path()
      ..moveTo(w * 0.08, h * 0.30)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.5, h * 0.92)
      ..lineTo(w * 0.08, h * 0.70)
      ..close();
    canvas.drawPath(
      leftFace,
      Paint()..color = const Color(0xFFFF7043),
    );

    // Right face
    final rightFace = Path()
      ..moveTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.92, h * 0.30)
      ..lineTo(w * 0.92, h * 0.70)
      ..lineTo(w * 0.5, h * 0.92)
      ..close();
    canvas.drawPath(
      rightFace,
      Paint()..color = const Color(0xFFE64A19),
    );

    // Sealing tape strip across top face
    final tape = Path()
      ..moveTo(w * 0.32, h * 0.18)
      ..lineTo(w * 0.40, h * 0.14)
      ..lineTo(w * 0.68, h * 0.42)
      ..lineTo(w * 0.60, h * 0.46)
      ..close();
    canvas.drawPath(
      tape,
      Paint()..color = const Color(0xFFFFCCBC).withValues(alpha: 0.9),
    );

    // Center seam line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.52),
      Offset(w * 0.5, h * 0.92),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Speech Bubble with 3 Horizontal Dots (Messages from dispatch)
class _ChatBubbleWithDots extends StatelessWidget {
  const _ChatBubbleWithDots();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 18,
      child: CustomPaint(
        painter: const _ChatBubblePainter(),
      ),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  const _ChatBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orange Bubble Body
    final bubble = Path();
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.84),
      const Radius.circular(5.5),
    );
    bubble.addRRect(r);

    // Speech bubble tail pointing bottom-left
    final tail = Path()
      ..moveTo(w * 0.22, h * 0.84)
      ..lineTo(w * 0.14, h)
      ..lineTo(w * 0.38, h * 0.84)
      ..close();
    bubble.addPath(tail, Offset.zero);

    canvas.drawPath(bubble, Paint()..color = const Color(0xFFFF5722));

    // 3 White Dots inside
    final dotPaint = Paint()..color = Colors.white;
    const dotRadius = 1.3;
    final dotY = h * 0.42;

    canvas.drawCircle(Offset(w * 0.32, dotY), dotRadius, dotPaint);
    canvas.drawCircle(Offset(w * 0.50, dotY), dotRadius, dotPaint);
    canvas.drawCircle(Offset(w * 0.68, dotY), dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CarrierDirect Swoosh Logo Painter (Fallback for vector rendering)
class _CarrierSwooshPainter extends CustomPainter {
  const _CarrierSwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5722)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1,
        size.width * 0.9,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.4,
        size.width * 0.3,
        size.height * 0.8,
      )
      ..close();
    canvas.drawPath(path1, paint);

    final path2 = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.5,
        size.width * 0.8,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.85,
        size.width * 0.3,
        size.height * 0.95,
      )
      ..close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
