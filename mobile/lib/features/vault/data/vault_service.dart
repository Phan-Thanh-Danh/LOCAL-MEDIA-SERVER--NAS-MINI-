import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService(ApiClient.instance);
});

class VaultService {
  final ApiClient _apiClient;

  VaultService(this._apiClient);

  Future<bool> getVaultStatus() async {
    final response = await _apiClient.get('/api/media/vault/status');
    return response['isSet'] ?? false;
  }

  Future<void> setVaultPassword(String? oldPassword, String newPassword) async {
    await _apiClient.post(
      '/api/media/vault/password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> lockFolder(String path, String password) async {
    await _apiClient.post(
      '/api/media/lock',
      data: {
        'path': path,
        'password': password,
      },
    );
  }

  Future<void> unlockFolder(String path, String password) async {
    await _apiClient.post(
      '/api/media/unlock',
      data: {
        'path': path,
        'password': password,
      },
    );
  }

  Future<void> hideFolder(String path, String password) async {
    await _apiClient.post(
      '/api/media/vault/hide',
      data: {
        'path': path,
        'password': password,
      },
    );
  }

  Future<void> unhideFolder(String path, String password) async {
    await _apiClient.post(
      '/api/media/vault/unhide',
      data: {
        'path': path,
        'password': password,
      },
    );
  }
  
  void setGlobalVaultPassword(String? password) {
    _apiClient.setVaultPassword(password);
  }
}
