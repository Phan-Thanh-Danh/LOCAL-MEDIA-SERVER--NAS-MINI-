import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../explorer/models/file_item.dart';
import '../../../core/utils/file_type_helper.dart';
import 'widgets/image_viewer.dart';
import 'widgets/video_viewer.dart';

class MediaPreviewScreen extends ConsumerWidget {
  final FileItem item;

  const MediaPreviewScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVideo = FileTypeHelper.isVideo(item.name, item.type);
    final isImage = FileTypeHelper.isImage(item.name, item.type);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black45,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          item.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Center(
        child: isVideo
            ? VideoViewer(item: item)
            : isImage
                ? ImageViewer(item: item)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.fileQuestion, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text('Định dạng không được hỗ trợ', style: TextStyle(color: Colors.white)),
                    ],
                  ),
      ),
    );
  }
}
