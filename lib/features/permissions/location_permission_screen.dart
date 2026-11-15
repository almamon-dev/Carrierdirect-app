import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/local_storage.dart';
import '../../services/location_service.dart';
import '../../shared/utils/app_toast.dart';

/// Screen 1: Allow Location Access (Intro Screen)
/// Screen 2: Clean Bottom-Sheet Modal requesting location permission
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final LocationService _locationService = LocationService();
  bool _isRequesting = false;

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

  void _navigateToSuccess() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.locationSuccess);
  }

  void _proceedToLogin() async {
    if (!mounted) return;
    try {
      await LocalStorage().setBool(AppConstants.keyOnboardingCompleted, true);
    } catch (_) {}
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _handleEnableLocation() async {
    setState(() => _isRequesting = true);
    try {
      final granted = await _locationService.requestPermission();
      if (!mounted) return;
      setState(() => _isRequesting = false);
      if (granted) {
        _navigateToSuccess();
      } else {
        _showLocationPermissionBottomSheet();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      _showLocationPermissionBottomSheet();
    }
  }

  /// Screen 2: Bottom-sheet Modal requesting location permission
  void _showLocationPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Drag Handle Pill
                    Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Folded Map with 3D Orange Pin & Radiating Accent Dashes
                    SizedBox(
                      width: 140,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Radiating accent dashes (orange)
                          const CustomPaint(
                            size: Size(140, 120),
                            painter: _RadiatingDashesPainter(
                              color: Color(0xFFFF5722),
                            ),
                          ),

                          // Folded map image with orange pin
                          Image.asset(
                            'assets/images/folded_map_pin.png',
                            width: 125,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.location_on_rounded,
                              size: 72,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title: "Allow CarrierDirect to access your location?"
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                        children: [
                          TextSpan(text: 'Allow '),
                          TextSpan(
                            text: 'CarrierDirect',
                            style: TextStyle(color: Color(0xFFFF5722)),
                          ),
                          TextSpan(text: ' to\naccess your location?'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      'We use your location to find nearby loads, provide turn-by-turn navigation, and track deliveries in real-time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF64748B),
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Button: "Allow While Using App" with rounded-[5px]
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          5.0,
                        ), // rounded-[5px]
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF3D00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722)
                                .withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isRequesting
                              ? null
                              : () async {
                                  setModalState(() => _isRequesting = true);
                                  setState(() => _isRequesting = true);

                                  final granted = await _locationService
                                      .requestPermission();

                                  if (!mounted) return;
                                  setModalState(() => _isRequesting = false);
                                  setState(() => _isRequesting = false);

                                  if (bottomSheetContext.mounted) {
                                    Navigator.of(bottomSheetContext).pop();
                                  }

                                  if (granted) {
                                    _navigateToSuccess();
                                  } else {
                                    _handlePermissionDenied();
                                  }
                                },
                          borderRadius: BorderRadius.circular(
                            5.0,
                          ), // rounded-[5px]
                          splashColor: Colors.white24,
                          child: Center(
                            child: _isRequesting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Allow While Using App',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Secondary Button: "Not Now" with rounded-[5px]
                    Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(
                          5.0,
                        ), // rounded-[5px]
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(bottomSheetContext).pop();
                            _proceedToLogin();
                          },
                          borderRadius: BorderRadius.circular(
                            5.0,
                          ), // rounded-[5px]
                          child: const Center(
                            child: Text(
                              'Not Now',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Feedback and retry handling when permission is denied
  void _handlePermissionDenied() async {
    final permanentlyDenied = await _locationService.isPermanentlyDenied();
    if (!mounted) return;

    if (permanentlyDenied) {
      AppToast.warning(
        context,
        'Location permission is permanently denied. Please enable it in Settings.',
        title: 'Location Access Needed',
        actionLabel: 'Settings',
        onAction: () => _locationService.openSettings(),
        duration: const Duration(seconds: 4),
      );
    } else {
      AppToast.warning(
        context,
        'Location access is required to receive loads. Tap "Enable Location" to retry.',
        title: 'Location Required',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    // Responsive Hero banner taking ~38% of screen height
    final heroHeight = (screenHeight * 0.38).clamp(220.0, 340.0);
    final bottomInset = mediaQuery.padding.bottom > 0
        ? mediaQuery.padding.bottom
        : 8.0;

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
            height: heroHeight + 15,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Sunset Highway Photo
                Image.asset(
                  'assets/images/allow_location.png',
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
            top: heroHeight - 34,
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
                  // Overlapping Folded Map Badge with Orange Pin & Radial Glow
                  Positioned(
                    top: -44,
                    child: SizedBox(
                      width: 110,
                      height: 94,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft orange radial aura glow behind the pin
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFFF5722)
                                      .withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/folded_map_pin.png',
                            width: 104,
                            height: 88,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.location_on_rounded,
                              size: 52,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sheet Body Content
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 46, 18, bottomInset + 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title: "Allow Location Access"
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                              children: [
                                TextSpan(text: 'Allow '),
                                TextSpan(
                                  text: 'Location',
                                  style: TextStyle(color: Color(0xFFFF4500)),
                                ),
                                TextSpan(text: ' Access'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Subtitle
                          const Text(
                            'Enable location access to discover nearby loads,\nget turn-by-turn navigation, and track deliveries.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // 1. Find nearby loads (with rounded-[5px])
                          _buildFeatureCard(
                            iconWidget: const Icon(
                              Icons.near_me_rounded,
                              color: Color(0xFFFF5722),
                              size: 22,
                            ),
                            title: 'Find nearby loads',
                            subtitle: 'Discover available shipments near your current route.',
                          ),

                          // 2. Accurate navigation (with rounded-[5px])
                          _buildFeatureCard(
                            iconWidget: const Icon(
                              Icons.navigation_rounded,
                              color: Color(0xFFFF5722),
                              size: 21,
                            ),
                            title: 'Accurate navigation',
                            subtitle: 'Optimized truck routes and real-time live traffic guidance.',
                          ),

                          // 3. Live delivery tracking (with rounded-[5px])
                          _buildFeatureCard(
                            iconWidget: const Icon(
                              Icons.share_location_rounded,
                              color: Color(0xFFFF5722),
                              size: 22,
                            ),
                            title: 'Live delivery tracking',
                            subtitle: 'Automated real-time trip status updates for dispatch.',
                          ),

                          // 4. Seamless facility check-in (with rounded-[5px])
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
                            title: 'Seamless facility check-in',
                            subtitle: 'Automatic geofence arrival detection at pickup & drop-off.',
                          ),

                          const SizedBox(height: 18),

                          // Primary Action Button: "Enable Location" with rounded-[5px]
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

  /// Feature Card with rounded-[5px] (BorderRadius.circular(5.0))
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
        borderRadius: BorderRadius.circular(4.0), // rounded-[4px]
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
          // Soft Peach Icon Container with rounded-[5px]
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EB),
              borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
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

  /// Primary Orange Gradient Action Button: "Enable Location"
  Widget _buildEnableButton() {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFF5722), Color(0xFFFF3D00)],
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
          onTap: _isRequesting ? null : _handleEnableLocation,
          borderRadius: BorderRadius.circular(5.0), // rounded-[5px]
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _isRequesting
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
                        Icons.near_me_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Enable Location',
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

  /// Secondary "Not Now" Hyperlink (Clean text link, matching Notification screen)
  Widget _buildNotNowLink() {
    return GestureDetector(
      onTap: _proceedToLogin,
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

/// Custom painter for small radiating accent dashes around illustrations
class _RadiatingDashesPainter extends CustomPainter {
  final Color color;
  const _RadiatingDashesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Left 2 dashes
    canvas.drawLine(Offset(cx - 56, cy - 14), Offset(cx - 44, cy - 8), paint);
    canvas.drawLine(Offset(cx - 52, cy + 6), Offset(cx - 42, cy + 3), paint);

    // Right 2 dashes
    canvas.drawLine(Offset(cx + 44, cy - 8), Offset(cx + 56, cy - 14), paint);
    canvas.drawLine(Offset(cx + 42, cy + 3), Offset(cx + 52, cy + 6), paint);
  }

  @override
  bool shouldRepaint(covariant _RadiatingDashesPainter oldDelegate) =>
      oldDelegate.color != color;
}
