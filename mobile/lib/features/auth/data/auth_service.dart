import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ApiClient.instance, SecureStorageService());
});

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  AuthService(this._apiClient, this._storageService);

  Future<bool> login(String username, String password) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    if (response != null && response['token'] != null) {
      await _storageService.saveToken(response['token']);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
}
