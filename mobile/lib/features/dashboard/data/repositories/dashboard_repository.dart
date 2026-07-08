import 'package:signalr_netcore/signalr_client.dart';
import '../../domain/models/system_metrics_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final token = ref.watch(authProvider).token;
  return DashboardRepository(token: token);
});

class DashboardRepository {
  late HubConnection _hubConnection;
  Function(SystemMetricsModel)? onMetricsReceived;

  DashboardRepository({String? token}) {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          "http://192.168.2.10:5000/hubs/media",
          options: HttpConnectionOptions(
            accessTokenFactory: token != null ? () async => token : null,
          ),
        )
        .build();
        
    _hubConnection.on("ReceiveSystemMetrics", _handleMetrics);
  }

  void _handleMetrics(List<Object?>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final data = arguments.first as Map<String, dynamic>;
        final metrics = SystemMetricsModel.fromJson(data);
        onMetricsReceived?.call(metrics);
      } catch (e) {
        print("Lỗi parse metrics: $e");
      }
    }
  }

  Future<void> startConnection() async {
    if (_hubConnection.state == HubConnectionState.Disconnected) {
      try {
        await _hubConnection.start();
      } catch (e) {
        print("SignalR Connection Error: $e");
      }
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.stop();
    }
  }
}
