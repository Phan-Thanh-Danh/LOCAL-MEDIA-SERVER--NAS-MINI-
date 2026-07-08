import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../dashboard/data/system_service.dart';

class ServerConfigScreen extends ConsumerStatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  ConsumerState<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends ConsumerState<ServerConfigScreen> {
  final _urlController = TextEditingController();
  final _storageService = SecureStorageService();
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final savedUrl = await _storageService.getBaseUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _urlController.text = savedUrl;
      // Optionally auto-check and navigate to login
      _checkAndProceed(savedUrl, auto: true);
    }
  }

  Future<void> _checkAndProceed(String url, {bool auto = false}) async {
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập địa chỉ máy chủ');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
      _urlController.text = url;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final systemService = ref.read(systemServiceProvider);
    final isConnected = await systemService.checkConnection(url);

    setState(() {
      _isChecking = false;
    });

    if (isConnected) {
      // Save and apply global URL
      await ApiClient.instance.updateBaseUrl(url);
      
      // Check if already logged in
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty && mounted) {
        context.go('/explorer');
      } else if (mounted) {
        context.go('/login');
      }
    } else {
      setState(() {
        _errorMessage = 'Không kết nối được server, vui lòng kiểm tra lại địa chỉ IP hoặc mạng LAN.';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  LucideIcons.hardDrive,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Cấu hình Server',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhập địa chỉ IP NAS của bạn\nVí dụ: http://192.168.1.10:5000',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    prefixIcon: const Icon(LucideIcons.globe),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _errorMessage,
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _checkAndProceed(value),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : () => _checkAndProceed(_urlController.text.trim()),
                    child: _isChecking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kết Nối',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
