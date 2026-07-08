import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService(ApiClient.instance, SecureStorageService());
});

class MediaService {
  final SecureStorageService _storageService;

  MediaService(ApiClient apiClient, this._storageService);

  Future<String> getMediaUrl(String relativePath, String type) async {
    final baseUrl = await _storageService.getBaseUrl() ?? '';
    final encodedPath = Uri.encodeComponent(relativePath).replaceAll('%2F', '/');
    
    // We don't embed the token in URL directly here, we let the video_player handle headers if possible.
    // If headers fail on Android/iOS video_player, we might need to append ?token=... (requires backend support).
    return '$baseUrl/api/media/$type/$encodedPath';
  }
  
  Future<Map<String, String>> getAuthHeaders() async {
    final headers = <String, String>{};
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    // Thêm Vault-Password nếu đang mở khóa thư mục ẩn
    final vaultPassword = ApiClient.instance.dio.options.headers['Vault-Password'];
    if (vaultPassword != null) {
      headers['Vault-Password'] = vaultPassword.toString();
    }
    
    return headers;
  }
}
