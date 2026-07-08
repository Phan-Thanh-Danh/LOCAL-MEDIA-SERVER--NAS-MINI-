import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // We cannot watch dioProvider directly if dioProvider watches authProvider (circular dependency).
  // So we create a separate basic Dio instance for login, or we can use the same dio instance if interceptor looks up dynamically.
  // We'll use a clean Dio instance just for Auth to avoid circular deps.
  final dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.2.10:5000/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<String> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/Auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data['token'] as String;
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Sai tài khoản hoặc mật khẩu');
      }
      throw Exception('Lỗi kết nối: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
