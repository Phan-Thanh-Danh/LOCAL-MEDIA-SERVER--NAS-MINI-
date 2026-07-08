import 'package:flutter_riverpod/flutter_riverpod.dart';

class VaultNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void unlock(String password) {
    state = password;
  }

  void lock() {
    state = null;
  }
}

final vaultProvider = NotifierProvider<VaultNotifier, String?>(VaultNotifier.new);
