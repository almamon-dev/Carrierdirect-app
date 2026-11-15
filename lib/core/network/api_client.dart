import 'dart:convert';
import 'dart:io';

import '../../app/config/api_config.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

class ApiClient {
  final String baseUrl;
  final HttpClient _httpClient;
  final ISecureStorage _secureStorage;

  ApiClient({
    String? baseUrl,
    HttpClient? httpClient,
    ISecureStorage? secureStorage,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _httpClient = httpClient ?? HttpClient(),
       _secureStorage = secureStorage ?? SecureStorage() {
    _httpClient.connectionTimeout = ApiConfig.connectTimeout;
  }

  Future<Map<String, String>> _headers([String? token]) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    final effectiveToken =
        token ?? await _secureStorage.read(AppConstants.keyAuthToken);
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    String? token,
    Map<String, String>? queryParams,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint')
          .replace(queryParameters: queryParams);
      final request = await _httpClient.getUrl(uri);

      final headers = await _headers(token);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _handleResponse(response.statusCode, responseBody, fromJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _httpClient.postUrl(uri);

      final headers = await _headers(token);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _handleResponse(response.statusCode, responseBody, fromJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    Map<String, dynamic>? body,
    String? token,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _httpClient.putUrl(uri);

      final headers = await _headers(token);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _handleResponse(response.statusCode, responseBody, fromJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    String? token,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final request = await _httpClient.deleteUrl(uri);

      final headers = await _headers(token);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return _handleResponse(response.statusCode, responseBody, fromJson);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  ApiResponse<T> _handleResponse<T>(
    int statusCode,
    String bodyStr,
    T Function(dynamic data)? fromJson,
  ) {
    if (statusCode >= 200 && statusCode < 300) {
      final dynamic body = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : null;
      final parsedData = fromJson != null && body != null
          ? fromJson(body)
          : body as T?;
      return ApiResponse.success(parsedData as T, statusCode: statusCode);
    } else {
      String errorMsg = 'Unknown error';
      if (bodyStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(bodyStr);
          if (decoded is Map && decoded['message'] != null) {
            errorMsg = decoded['message'].toString();
          } else {
            errorMsg = bodyStr;
          }
        } catch (_) {
          errorMsg = bodyStr;
        }
      }
      throw ApiException(errorMsg, statusCode: statusCode);
    }
  }
}
