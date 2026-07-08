import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';
  static const String _baseUrlKey = 'base_url';

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Base URL
  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url);
  }

  Future<String?> getBaseUrl() async {
    final stored = await _storage.read(key: _baseUrlKey);
    return stored ?? 'http://192.168.2.10:5000';
  }

  Future<void> deleteBaseUrl() async {
    await _storage.delete(key: _baseUrlKey);
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
