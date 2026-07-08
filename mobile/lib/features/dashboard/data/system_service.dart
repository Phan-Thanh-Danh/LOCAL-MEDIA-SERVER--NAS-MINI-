import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_info.dart';

final systemServiceProvider = Provider<SystemService>((ref) {
  return SystemService(ApiClient.instance);
});

class SystemService {
  final ApiClient _apiClient;

  SystemService(this._apiClient);

  Future<bool> checkConnection(String baseUrl) async {
    try {
      final dio = _apiClient.dio;
      // Temporary change baseUrl for check
      final response = await dio.get(
        '$baseUrl/api/system/status',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<DashboardInfo> getDashboardInfo() async {
    final response = await _apiClient.get('/api/system/dashboard');
    return DashboardInfo.fromJson(response);
  }
}
