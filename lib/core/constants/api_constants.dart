class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://bedb-103-152-107-148.ngrok-free.app/api/v1';
  static const String googleMapsApiKey = 'AIzaSyCpMW2SPdb1R3vzV3FsxqM2VEBM4iWhDZk';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // Driver endpoints
  static const String driverProfile = '/driver/profile';
  static const String updateLocation = '/driver/location';
  static const String toggleOnlineStatus = '/driver/status';

  // Trips & Deliveries
  static const String trips = '/trips';
  static const String tripDetails = '/trips/{id}';
  static const String acceptTrip = '/trips/{id}/accept';
  static const String completeTrip = '/trips/{id}/complete';
}
