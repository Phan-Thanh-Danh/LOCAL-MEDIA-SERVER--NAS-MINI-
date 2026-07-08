import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  late Dio _dio;
  final SecureStorageService _storageService;
  
  // Singleton pattern for global access (or can be provided via Riverpod)
  static final ApiClient _instance = ApiClient._internal(SecureStorageService());
  static ApiClient get instance => _instance;

  ApiClient._internal(this._storageService) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically attach BaseURL
        final baseUrl = await _storageService.getBaseUrl();
        if (baseUrl != null && baseUrl.isNotEmpty) {
          options.baseUrl = baseUrl;
        }

        // Automatically attach Token
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          // Token expired or invalid
          _storageService.deleteToken();
          // We can broadcast an event here to navigate to Login
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> updateBaseUrl(String url) async {
    await _storageService.saveBaseUrl(url);
    _dio.options.baseUrl = url;
  }

  // Method to set vault password globally for requests
  void setVaultPassword(String? password) {
    if (password != null && password.isNotEmpty) {
      _dio.options.headers['Vault-Password'] = password;
    } else {
      _dio.options.headers.remove('Vault-Password');
    }
  }

  // Generic GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  // Generic POST request
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  void _handleDioError(DioException e) {
    if (e.response != null) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      final message = e.response?.data is Map 
          ? (e.response?.data['message'] ?? e.response?.data.toString()) 
          : e.response?.data?.toString();
      throw ApiException(message ?? 'Server error', e.response?.statusCode);
    } else if (e.type == DioExceptionType.connectionTimeout || 
               e.type == DioExceptionType.receiveTimeout) {
      throw ApiException('Connection timed out. Please check your network.');
    } else {
      throw ApiException('Network error: ${e.message}');
    }
  }
}
