import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/storage/local_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _localStorage = LocalStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _localStorage.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, dynamic>? data}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.post(
      url,
      headers: headers,
      body: data != null ? jsonEncode(data) : null,
    );
  }

  Future<http.Response> put(String endpoint, {Map<String, dynamic>? data}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _headers();
    return await http.put(
      url,
      headers: headers,
      body: data != null ? jsonEncode(data) : null,
    );
  }
}
