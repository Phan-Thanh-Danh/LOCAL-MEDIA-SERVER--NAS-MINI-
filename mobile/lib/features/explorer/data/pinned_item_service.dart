import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final pinnedItemServiceProvider = Provider<PinnedItemService>((ref) {
  return PinnedItemService(ApiClient.instance);
});

class PinnedItemService {
  final ApiClient _apiClient;

  PinnedItemService(this._apiClient);

  Future<void> pinItem(String path) async {
    await _apiClient.post(
      '/api/files/pin',
      data: {'path': path},
    );
  }

  Future<void> unpinItem(String path) async {
    await _apiClient.post(
      '/api/files/unpin',
      data: {'path': path},
    );
  }
}
