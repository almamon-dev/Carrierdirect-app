import 'package:flutter/material.dart';

// User Authentic Core Screens (Dashboard, Profile, Auth)
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

// Screen 1, 2, 3 Onboarding & Permissions (Matching User Mockup Image)
import '../../features/onboarding/presentation/screens/admin_approval_screen.dart';
import '../../features/onboarding/presentation/screens/location_success_screen.dart';
import '../../features/permissions/location_permission_screen.dart';
import '../../features/permissions/notification_permission_screen.dart';
import '../../features/splash/splash_screen.dart';

// Real Trips & Navigation
import '../../features/trips/presentation/screens/in_app_navigation_screen.dart';
import '../../features/trips/presentation/screens/shipment_details_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // 1. Splash Screen (Screen 1 from mockup)
      case AppRoutes.initial:
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // 2. Location Permission Screen (Screen 2: "Allow Location Access" from mockup)
      case AppRoutes.locationPermission:
      case AppRoutes.locationIntro:
      case AppRoutes.onboarding:
      case AppRoutes.onboardingIntro:
        return MaterialPageRoute(
          builder: (_) => const LocationPermissionScreen(),
        );

      // 3. Location Success Screen (Screen 6: "Location Enabled" Success State)
      case AppRoutes.locationSuccess:
        return MaterialPageRoute(builder: (_) => const LocationSuccessScreen());

      // 4. Notification Permission Screen (Screen 3: "Stay Updated" from mockup)
      case AppRoutes.notificationPermission:
        return MaterialPageRoute(
          builder: (_) => const NotificationPermissionScreen(),
        );

      // 4. Credential Login Screen (User's authentic LoginScreen)
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // 5. Forgot Password Screen
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // 6. Complete Profile Step & Dashboard
      case AppRoutes.dashboard:
      case AppRoutes.profileSetup:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      // 6.1 Admin Approval Screen (Locked until admin verifies driver)
      case AppRoutes.adminApproval:
        return MaterialPageRoute(builder: (_) => const AdminApprovalScreen());

      // 7. Profile & Edit Profile Screens
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case AppRoutes.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      // 8. GPS Navigation / Tracking
      case AppRoutes.gpsTracker:
        if (args is ShipmentItem) {
          return MaterialPageRoute(
            builder: (_) => InAppNavigationScreen(shipment: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const TripsScreen());

      // 9. Shipment Details
      case AppRoutes.orderDetails:
        if (args is ShipmentItem) {
          return MaterialPageRoute(
            builder: (_) => ShipmentDetailsScreen(shipment: args),
          );
        }
        return MaterialPageRoute(builder: (_) => const TripsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
