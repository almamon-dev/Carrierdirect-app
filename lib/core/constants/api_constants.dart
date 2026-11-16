import '../../services/app_config_service.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => AppConfigService().apiBaseUrl;
  static String get googleMapsApiKey => AppConfigService().googleMapsApiKey;

  // App bootstrap configuration
  static const String appConfig = '/app-config';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String verify2faLogin = '/auth/2fa-verify';
  static const String authMe = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // Driver endpoints
  static const String driverProfile = '/driver/profile';
  static const String completeProfileSetup = '/driver/profile/setup';
  static const String verificationStatus = '/driver/verification-status';
  static const String updateLocation = '/driver/location';
  static const String toggleOnlineStatus = '/driver/status';
  static const String deviceToken = '/driver/device-token';
  static const String notificationSettings = '/driver/notification-settings';
  static const String changePassword = '/driver/change-password';
  static const String setup2fa = '/driver/2fa/setup';
  static const String enable2fa = '/driver/2fa/enable';
  static const String disable2fa = '/driver/2fa/disable';

  // Driver Notifications
  static const String driverNotifications = '/driver/notifications';
  static const String markAllNotificationsRead =
      '/driver/notifications/mark-all-read';
  static const String clearAllNotifications = '/driver/notifications/clear-all';

  // Dashboard & Shipments
  static const String driverDashboard = '/driver/dashboard';
  static const String driverShipments = '/driver/shipments';
  static const String driverShipmentDetails = '/driver/shipments/{id}';
  static const String driverShipmentStatus = '/driver/shipments/{id}/status';
  static const String driverShipmentHandover = '/driver/shipments/{id}/handover';
  static const String driverShipmentHandoverCancel =
      '/driver/shipments/{id}/handover/cancel';
  static const String driverShipmentHandoverAccept =
      '/driver/shipments/{id}/handover/accept';
  static const String driverShipmentHandoverReject =
      '/driver/shipments/{id}/handover/reject';

  // Trips & Deliveries
  static const String trips = '/trips';
  static const String tripDetails = '/trips/{id}';
  static const String acceptTrip = '/trips/{id}/accept';
  static const String completeTrip = '/trips/{id}/complete';

  // Live Chat & Direct Messaging (matches Web /messages/*)
  static const String chatConversations = '/messages/conversations';
  static const String chatDirectoryUsers = '/messages/users';
  static const String chatUnreadCount = '/messages/unread-count';
  static const String chatSendMessage = '/messages/send';
  static const String chatHeartbeat = '/messages/heartbeat';
}
