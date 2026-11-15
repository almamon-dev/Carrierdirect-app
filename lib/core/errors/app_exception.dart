class AppException implements Exception {
  final String message;
  final String? prefix;
  final int? statusCode;

  AppException(this.message, {this.prefix, this.statusCode});

  @override
  String toString() {
    if (prefix != null) {
      return '$prefix: $message';
    }
    return message;
  }
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.statusCode})
    : super(prefix: 'Network Error');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Unauthorized access'])
    : super(prefix: 'Auth Error', statusCode: 401);
}

class ServerException extends AppException {
  ServerException(super.message, {super.statusCode})
    : super(prefix: 'Server Error');
}

class ValidationException extends AppException {
  ValidationException(super.message) : super(prefix: 'Validation Error');
}

class CacheException extends AppException {
  CacheException(super.message) : super(prefix: 'Cache Error');
}
