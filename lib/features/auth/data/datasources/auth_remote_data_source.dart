import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> forgotPassword({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> logout();
}

class AuthRemoteDataSource implements IAuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      endpoint: ApiConstants.login,
      body: {
        'email': email,
        'password': password,
        'device_type': 'android',
      },
      fromJson: (data) {
        if (data is Map<String, dynamic>) {
          final userJson = (data['data'] != null && data['data']['user'] != null)
              ? data['data']['user'] as Map<String, dynamic>
              : (data['user'] != null ? data['user'] as Map<String, dynamic> : data);
          final token = data['access_token']?.toString() ?? data['token']?.toString();
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
