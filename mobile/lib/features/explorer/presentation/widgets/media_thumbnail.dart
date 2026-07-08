import 'package:flutter/material.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/file_type_helper.dart';
import '../../models/file_item.dart';

class MediaThumbnail extends StatefulWidget {
  final FileItem item;
  final double width;
  final double height;
  final Widget fallback;
  final double borderRadius;

  const MediaThumbnail({
    super.key,
    required this.item,
    required this.width,
    required this.height,
    required this.fallback,
    this.borderRadius = 12.0,
  });

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  final _storageService = SecureStorageService();
  String? _imageUrl;
  Map<String, String>? _headers;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final baseUrl = await _storageService.getBaseUrl();
    final token = await _storageService.getToken();
    
    if (baseUrl != null && baseUrl.isNotEmpty) {
      final encodedPath = Uri.encodeComponent(widget.item.relativePath).replaceAll('%2F', '/');
      
      final isVideo = FileTypeHelper.isVideo(widget.item.name, widget.item.type);
      final endpoint = isVideo ? 'thumbnail' : 'image';
      final fullUrl = '$baseUrl/api/media/$endpoint/$encodedPath';
      
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // If vault password is set globally in ApiClient
      final vaultPassword = ApiClient.instance.dio.options.headers['Vault-Password'];
      if (vaultPassword != null) {
        headers['Vault-Password'] = vaultPassword.toString();
      }

      if (mounted) {
        setState(() {
          _imageUrl = fullUrl;
          _headers = headers;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl == null || _headers == null) {
      return widget.fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        _imageUrl!,
        headers: _headers,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return widget.fallback; // Fallback to icon if thumbnail fails to load
        },
      ),
    );
  }
}
