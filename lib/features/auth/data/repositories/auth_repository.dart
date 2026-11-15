import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> verify2faLogin({
    required String email,
    required String code,
  });
  Future<void> forgotPassword({required String email});
  Future<bool> verifyOtp({required String email, required String otp});
  Future<void> logout();
  Future<bool> isAuthenticated();
}

class AuthRepository implements IAuthRepository {
  final IAuthRemoteDataSource _remoteDataSource;
  final ISecureStorage _secureStorage;
  final ILocalStorage _localStorage;

  AuthRepository({
    IAuthRemoteDataSource? remoteDataSource,
    ISecureStorage? secureStorage,
    ILocalStorage? localStorage,
  }) : _remoteDataSource = remoteDataSource ?? AuthRemoteDataSource(),
       _secureStorage = secureStorage ?? SecureStorage(),
       _localStorage = localStorage ?? LocalStorage();

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    if (user.token != null && user.token!.isNotEmpty) {
      await _secureStorage.write(AppConstants.keyAuthToken, user.token!);
      await _localStorage.setString(AppConstants.keyAuthToken, user.token!);
      await _localStorage.setString(
        AppConstants.keyUserData,
        jsonEncode(user.toJson()),
      );
    }
    await _localStorage.setString(AppConstants.keySavedEmail, email);
    return user;
  }

  @override
  Future<UserModel> verify2faLogin({
    required String email,
    required String code,
  }) async {
    final user = await _remoteDataSource.verify2faLogin(
      email: email,
      code: code,
    );
    if (user.token != null && user.token!.isNotEmpty) {
      await _secureStorage.write(AppConstants.keyAuthToken, user.token!);
      await _localStorage.setString(AppConstants.keyAuthToken, user.token!);
      await _localStorage.setString(
        AppConstants.keyUserData,
        jsonEncode(user.toJson()),
      );
    }
    await _localStorage.setString(AppConstants.keySavedEmail, email);
    return user;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<bool> verifyOtp({required String email, required String otp}) async {
    return await _remoteDataSource.verifyOtp(email: email, otp: otp);
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {}
    await _secureStorage.delete(AppConstants.keyAuthToken);
    await _secureStorage.delete(AppConstants.keyRefreshToken);
    await _localStorage.remove(AppConstants.keyUserData);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(AppConstants.keyAuthToken);
    return token != null && token.isNotEmpty;
  }
}
