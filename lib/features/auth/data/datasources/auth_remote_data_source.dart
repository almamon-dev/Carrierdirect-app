import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> verify2faLogin({
    required String email,
    required String code,
  });
  Future<void> forgotPassword({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> logout();
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      endpoint: ApiConstants.login,
      body: {'email': email, 'password': password, 'device_type': 'android'},
      fromJson: (data) {
        if (data is Map<String, dynamic>) {
          final innerData = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
          final requires2fa =
              innerData?['requires_2fa'] == true ||
              data['requires_2fa'] == true;
          final userJson = (innerData != null && innerData['user'] is Map)
              ? Map<String, dynamic>.from(innerData['user'] as Map)
              : (data['user'] is Map
                    ? Map<String, dynamic>.from(data['user'] as Map)
                    : data);
          final token =
              data['access_token']?.toString() ?? data['token']?.toString();
          return UserModel.fromJson(
            userJson,
            token: token,
            requires2fa: requires2fa,
          );
        }
        return UserModel(id: '', email: email, fullName: '');
      },
    );
    return response.data!;
  }

  @override
  Future<UserModel> verify2faLogin({
    required String email,
    required String code,
  }) async {
    final response = await _apiClient.post(
      endpoint: ApiConstants.verify2faLogin,
      body: {'email': email, 'code': code, 'device_type': 'android'},
      fromJson: (data) {
        if (data is Map<String, dynamic>) {
          final innerData = data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : null;
          final userJson = (innerData != null && innerData['user'] is Map)
              ? Map<String, dynamic>.from(innerData['user'] as Map)
              : (data['user'] is Map
                    ? Map<String, dynamic>.from(data['user'] as Map)
                    : data);
          final token =
              data['access_token']?.toString() ?? data['token']?.toString();
          return UserModel.fromJson(userJson, token: token);
        }
        return UserModel(id: '', email: email, fullName: '');
      },
    );
    return response.data!;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post(
      endpoint: ApiConstants.forgotPassword,
      body: {'email': email},
    );
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    final response = await _apiClient.post(
      endpoint: ApiConstants.verifyOtp,
      body: {'email': email, 'otp': otp},
    );
    return response.success;
  }

  @override
  Future<void> logout() async {
    await _apiClient.post(endpoint: ApiConstants.logout);
  }
}
