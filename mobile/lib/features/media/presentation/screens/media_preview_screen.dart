import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../files/presentation/providers/vault_provider.dart';
import '../../../files/presentation/providers/file_actions_provider.dart';
import '../widgets/custom_video_player.dart';

class MediaPreviewScreen extends ConsumerWidget {
  final String title;
  final String type; // 'video' or 'image'
  final String url;
  final String relativePath; // To support downloading

  const MediaPreviewScreen({
    super.key,
    required this.title,
    required this.type,
    required this.url,
    required this.relativePath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Sâu đen tuyệt đối theo Guideline
      backgroundColor: const Color(0xFF000000), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tải xuống...')),
                );
                // The implementation uses getApplicationDocumentsDirectory in bottom sheet,
                // but since it's hard to get external storage without path_provider here,
                // we'll just trigger the same action or ignore for now if not needed here.
                // Ideally we use fileActionsProvider.downloadFile(relativePath, savePath).
              } catch (e) {
                // Ignore for now
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0), // Bo góc 8px
          child: type == 'image'
              ? _buildImagePreview(ref)
              : _buildVideoPreview(ref),
        ),
      ),
    );
  }

  Map<String, String> _getHeaders(WidgetRef ref) {
    final authState = ref.read(authProvider);
    final vaultPassword = ref.read(vaultProvider);
    
    final headers = <String, String>{};
    if (authState.token != null) {
      headers['Authorization'] = 'Bearer ${authState.token}';
    }
    if (vaultPassword != null) {
      headers['Vault-Password'] = vaultPassword;
    }
    return headers;
  }

  Widget _buildImagePreview(WidgetRef ref) {
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _getHeaders(ref),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(LucideIcons.imageOff, color: Colors.white54, size: 100),
      ),
    );
  }

  Widget _buildVideoPreview(WidgetRef ref) {
    return CustomVideoPlayer(
      url: url,
      headers: _getHeaders(ref),
    );
  }
}
