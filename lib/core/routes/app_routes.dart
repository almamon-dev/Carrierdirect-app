/// Central Route Name Constants for CarrierDirect Driver App
class AppRoutes {
  AppRoutes._();

  // Screen 1: Splash Screen
  static const String initial = '/';
  static const String splash = '/splash';

  // Screen 2 & 3: Permissions
  static const String locationPermission = '/permissions/location';
  static const String notificationPermission = '/permissions/notification';

  // Screen 4 & 5: Authentication
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';

  // Screen 6: Profile Setup ("Complete Your Profile")
  static const String profileSetup = '/profile/setup';
  static const String adminApproval = '/admin-approval';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Screen 7: Onboarding Intro ("You're Ready to Drive")
  static const String onboardingIntro = '/onboarding/intro';

  // Screen 8: Driver Dashboard (Online)
  static const String dashboard = '/dashboard';

  // Screen 9: GPS Tracker (Active Job)
  static const String gpsTracker = '/gps-tracker';

  // Screen 10: Order Tracking (Details)
  static const String orderDetails = '/order-details';

  // Legacy route aliases for backward compatibility
  static const String onboarding = '/onboarding';
  static const String locationIntro = '/location-intro';
  static const String locationSuccess = '/location-success';
}
