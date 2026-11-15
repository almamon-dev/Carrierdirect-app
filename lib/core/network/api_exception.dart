import '../errors/app_exception.dart';

class ApiException extends AppException {
  ApiException(
    super.message, {
    super.statusCode,
    super.prefix = 'API Exception',
  });

  factory ApiException.fromStatusCode(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return ApiException('Bad Request: $message', statusCode: 400);
      case 401:
        return ApiException('Unauthorized: $message', statusCode: 401);
      case 403:
        return ApiException('Forbidden: $message', statusCode: 403);
      case 404:
        return ApiException('Not Found: $message', statusCode: 404);
      case 500:
      default:
        return ApiException('Server Error: $message', statusCode: statusCode);
    }
  }
}
