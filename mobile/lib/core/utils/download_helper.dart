import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class DownloadHelper {
  static Future<void> downloadAndShareOrOpen(
    BuildContext context, 
    String relativePath, 
    String fileName,
    String? token,
    String? baseUrl,
  ) async {
    try {
      if (baseUrl == null || baseUrl.isEmpty) {
        throw Exception('Base URL is missing');
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang tải "$fileName"...')),
      );

      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName';

      final dio = Dio();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final url = '$baseUrl/api/media/download/${Uri.encodeComponent(relativePath)}';

      await dio.download(
        url,
        savePath,
        options: Options(headers: headers),
      );

      // Hide loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Ask user to open or share
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Đã tải xong', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Mở file'),
                  onTap: () {
                    Navigator.pop(context);
                    OpenFilex.open(savePath);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Chia sẻ / Lưu vào máy'),
                  onTap: () {
                    Navigator.pop(context);
                    Share.shareXFiles([XFile(savePath)], text: fileName);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải file: $e')),
        );
      }
    }
  }
}
