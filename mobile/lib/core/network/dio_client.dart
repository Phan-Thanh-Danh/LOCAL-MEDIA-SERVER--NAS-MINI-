import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/files/presentation/providers/vault_provider.dart';
import 'package:flutter/foundation.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.2.10:5000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Lấy token từ state
        final authState = ref.read(authProvider);
        if (authState.token != null) {
          options.headers['Authorization'] = 'Bearer ${authState.token}';
        }
        
        final vaultPassword = ref.read(vaultProvider);
        if (vaultPassword != null) {
          options.headers['Vault-Password'] = vaultPassword;
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // TODO: Có thể handle tự động logout nếu token hết hạn
          debugPrint('Unauthorized! Need to login again.');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
