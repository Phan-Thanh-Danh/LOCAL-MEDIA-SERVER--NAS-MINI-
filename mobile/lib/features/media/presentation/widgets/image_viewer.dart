import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import '../../data/media_service.dart';
import '../../../explorer/models/file_item.dart';

class ImageViewer extends ConsumerWidget {
  final FileItem item;

  const ImageViewer({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaService = ref.watch(mediaServiceProvider);

    return FutureBuilder<String>(
      future: mediaService.getMediaUrl(item.relativePath, 'image'),
      builder: (context, snapshotUrl) {
        if (!snapshotUrl.hasData) {
          return const CircularProgressIndicator(color: Colors.white);
        }
        
        return FutureBuilder<Map<String, String>>(
          future: mediaService.getAuthHeaders(),
          builder: (context, snapshotHeaders) {
            if (!snapshotHeaders.hasData) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            
            return PhotoView(
              imageProvider: NetworkImage(
                snapshotUrl.data!,
                headers: snapshotHeaders.data,
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.error, color: Colors.red, size: 64),
              ),
            );
          },
        );
      },
    );
  }
}
