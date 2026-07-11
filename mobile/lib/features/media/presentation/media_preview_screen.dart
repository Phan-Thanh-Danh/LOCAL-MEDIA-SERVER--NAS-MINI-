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

class MediaPreviewScreen extends ConsumerStatefulWidget {
  final List<FileItem> items;
  final int initialIndex;

  const MediaPreviewScreen({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends ConsumerState<MediaPreviewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black45,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('No media found', style: TextStyle(color: Colors.white))),
      );
    }

    final currentItem = widget.items[_currentIndex];
    final isText = FileTypeHelper.isText(currentItem.name, currentItem.type);

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
          currentItem.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isVideo = FileTypeHelper.isVideo(item.name, item.type);
          final isImage = FileTypeHelper.isImage(item.name, item.type);
          final isPdf = FileTypeHelper.isPdf(item.name, item.type);
          final isTextFile = FileTypeHelper.isText(item.name, item.type);
          final isWord = FileTypeHelper.isWord(item.name, item.type);

          return Center(
            child: isVideo
                ? VideoViewer(item: item)
                : isImage
                    ? ImageViewer(item: item)
                    : isPdf
                        ? PdfViewerWidget(item: item)
                        : isTextFile
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
          );
        },
      ),
    );
  }
}
