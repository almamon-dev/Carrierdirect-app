import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../services/app_config_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../auth/data/repositories/auth_repository.dart';

/// Clean Minimal Animated Splash Screen with Real Session Validation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _navTimer;
  Timer? _animDelayTimer;
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _pulseAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0F172A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // 1. Entrance animation (Dramatic scale + fade + slide)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.0, 0.90, curve: Curves.easeOutCubic),
          ),
        );

    // 2. Continuous subtle breathing pulse after entrance
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Start entrance animation cleanly after first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage('assets/images/Logo.png'), context);
      _animDelayTimer = Timer(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        _entranceController.forward().then((_) {
          if (mounted) {
            _pulseController.repeat(reverse: true);
          }
        });
      });
    });

    // Auto navigate after minimal branding delay
    _navTimer = Timer(const Duration(milliseconds: 2500), _navigateToNext);
  }

  void _navigateToNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _navTimer?.cancel();
    _animDelayTimer?.cancel();

    try {
      // Hydrate runtime config (Google Maps key, GPS interval, FCM & maintenance status)
      await AppConfigService().loadRemoteConfig();
      if (!mounted) return;

      if (AppConfigService().maintenanceMode) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Scheduled Maintenance'),
            content: Text(AppConfigService().maintenanceMessage),
          ),
        );
        return;
      }

      final isLocationGranted = await LocationService().checkPermission();
      final isOnboardingDone =
          await LocalStorage().getBool(AppConstants.keyOnboardingCompleted) ??
              false;

      // 1. First Launch or Location Permission Missing Gate
      // If location is not yet granted on device, or onboarding not completed:
      if (!isLocationGranted || !isOnboardingDone) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.locationPermission,
        );
        return;
      }

      // 2. Returning Driver with Location Enabled: Validate Session Token
      final token = await SecureStorage().read(AppConstants.keyAuthToken) ??
          await LocalStorage().getString(AppConstants.keyAuthToken);

      if (token != null && token.isNotEmpty) {
        try {
          final uri = Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.driverProfile}',
          );
          final res = await http
              .get(
                uri,
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                  'ngrok-skip-browser-warning': 'true',
                },
              )
              .timeout(const Duration(seconds: 4));

          if (!mounted) return;

          if (res.statusCode == 200) {
            final dynamic body = jsonDecode(res.body);
            final data = body is Map<String, dynamic> &&
                    body['data'] is Map<String, dynamic>
                ? body['data'] as Map<String, dynamic>
                : <String, dynamic>{};
            final verificationMap = data['verification'] is Map
                ? data['verification'] as Map<String, dynamic>
                : <String, dynamic>{};
            final isVerified = data['is_verified'] == true ||
                verificationMap['is_verified'] == true;
            final status = (data['verification_status'] ??
                    verificationMap['status'] ??
                    '')
                .toString()
                .toLowerCase();

            if (!isVerified || (status != 'verified' && status != 'approved')) {
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.adminApproval,
              );
              return;
            }

            // Valid, verified returning driver -> Sync Push Token & Notification Check -> Driver Dashboard
            final isNotifGranted =
                await NotificationService().checkPermission();
            if (!mounted) return;

            if (isNotifGranted) {
              unawaited(NotificationService().syncTokenWithBackend());
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            } else {
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.notificationPermission,
              );
            }
            return;
          } else if (res.statusCode == 401) {
            // Token expired -> clean logout & redirect to login
            await AuthRepository().logout();
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            return;
          } else {
            // Server error / temporary backend issue -> grant offline Dashboard access
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            return;
          }
        } catch (_) {
          // Timeout or offline -> allow entering Dashboard with cached data
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
          return;
        }
      }

      // 3. Unauthenticated Driver with Location Enabled -> Login Screen
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _animDelayTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Boro logo: 80% of screen width, max 360
    final logoWidth = (screenWidth * 0.82).clamp(280.0, 360.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: GestureDetector(
        onTap: _navigateToNext,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _pulseController,
            ]),
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _pulseController.isAnimating
                      ? _pulseAnimation
                      : _scaleAnimation,
                  child: FadeTransition(opacity: _fadeAnimation, child: child),
                ),
              );
            },
            child: Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/Logo.png',
                width: logoWidth,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'CarrierDirect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
