import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../explorer/models/file_item.dart';
import '../../../core/utils/file_type_helper.dart';
import 'widgets/image_viewer.dart';
import 'widgets/video_viewer.dart';
import 'widgets/pdf_viewer_widget.dart';
import 'widgets/text_viewer_widget.dart';
import '../../../core/utils/download_helper.dart';
import '../../../core/storage/secure_storage_service.dart';

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
    final isPdf = FileTypeHelper.isPdf(item.name, item.type);
    final isText = FileTypeHelper.isText(item.name, item.type);
    final isWord = FileTypeHelper.isWord(item.name, item.type);

    return Scaffold(
      backgroundColor: isText ? Colors.white : Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isText ? Colors.black87 : Colors.black45,
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
                : isPdf
                    ? PdfViewerWidget(item: item)
                    : isText
                        ? TextViewerWidget(item: item)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isWord ? LucideIcons.fileText : LucideIcons.fileQuestion, color: Colors.white, size: 64),
                              const SizedBox(height: 16),
                              Text(isWord ? 'Định dạng Word cần mở bằng ứng dụng ngoài' : 'Định dạng không được hỗ trợ', style: const TextStyle(color: Colors.white)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final storage = SecureStorageService();
                                  final token = await storage.getToken();
                                  final baseUrl = await storage.getBaseUrl();
                                  if (context.mounted) {
                                    DownloadHelper.downloadAndShareOrOpen(
                                      context,
                                      item.relativePath,
                                      item.name,
                                      token,
                                      baseUrl,
                                    );
                                  }
                                },
                                icon: const Icon(LucideIcons.externalLink),
                                label: const Text('Mở bằng ứng dụng khác'),
                              ),
                            ],
                          ),
      ),
    );
  }
}
