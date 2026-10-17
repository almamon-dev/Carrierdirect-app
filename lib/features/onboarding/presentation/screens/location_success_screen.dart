import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/storage/local_storage.dart';


class LocationSuccessScreen extends StatefulWidget {
  const LocationSuccessScreen({super.key});

  @override
  State<LocationSuccessScreen> createState() => _LocationSuccessScreenState();
}

class _LocationSuccessScreenState extends State<LocationSuccessScreen> {
  final _localStorage = LocalStorage();

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

  Future<void> _handleContinue() async {
    // Mark location permission & onboarding step as complete
    await _localStorage.setBool(AppConstants.keyLocationPermissionGranted, true);
    await _localStorage.setBool(AppConstants.keyOnboardingCompleted, true);

    if (mounted) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      // Navigate to the existing Driver Login screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    // Hero banner taking ~60% of the screen height so the highway truck photo is fully showcased
    final heroHeight = screenHeight * 0.60;
    final bottomInset =
        mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom : 10.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Top Section: Prominent Sunset Highway Truck Photo with CarrierDirect Logo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight + 25,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Highway photo
                Image.asset(
                  'assets/images/allow_location.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.2, -0.15),
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

          // 2. White Bottom Sheet Container with Top-Rounded Corners & Compact Spacing
          Positioned(
            top: heroHeight - 20,
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
                  // Overlapping Folded Map with 3D Green Checkmark & Radiating Dashes
                  Positioned(
                    top: -50,
                    child: SizedBox(
                      width: 140,
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Soft green radial aura glow behind checkmark
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF10B981).withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Radiating accent dashes (green)
                          const CustomPaint(
                            size: Size(140, 110),
                            painter: _GreenRadiatingDashesPainter(
                              color: Color(0xFF10B981),
                            ),
                          ),

                          // Folded map image with green checkmark
                          Image.asset(
                            'assets/images/folded_map_success.png',
                            width: 130,
                            height: 104,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sheet Body Content with Balanced Spacing
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      56,
                      24,
                      bottomInset + 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(height: 6),

                            // Title: "Location Enabled!"
                            Text(
                              'Location Enabled!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 10),

                            // Subtitle
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Your location is now enabled. We can find nearby loads, provide navigation, and track your deliveries in real-time.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Primary Orange Button: "Continue ->" with rounded-[5px]
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _buildContinueButton(),
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
    );
  }

  /// Primary Orange Gradient Action Button: "Continue ->" with rounded-[5px]
  Widget _buildContinueButton() {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
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
          onTap: _handleContinue,
          borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Expanded(
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

  /// CarrierDirect Logo with Brand Name
  Widget _buildCarrierDirectLogo() {
    return Image.asset(
      'assets/images/Logo.png',
      height: 36,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => RichText(
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
    );
  }
}

/// Custom painter for green radiating accent dashes around success badge
class _GreenRadiatingDashesPainter extends CustomPainter {
  final Color color;
  const _GreenRadiatingDashesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2 - 4;

    // Left 2 dashes
    canvas.drawLine(Offset(cx - 56, cy - 14), Offset(cx - 44, cy - 8), paint);
    canvas.drawLine(Offset(cx - 52, cy + 6), Offset(cx - 42, cy + 3), paint);

    // Right 2 dashes
    canvas.drawLine(Offset(cx + 44, cy - 8), Offset(cx + 56, cy - 14), paint);
    canvas.drawLine(Offset(cx + 42, cy + 3), Offset(cx + 52, cy + 6), paint);
  }

  @override
  bool shouldRepaint(covariant _GreenRadiatingDashesPainter oldDelegate) =>
      oldDelegate.color != color;
}
