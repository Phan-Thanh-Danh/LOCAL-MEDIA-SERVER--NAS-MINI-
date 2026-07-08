import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/file_item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filesRepositoryProvider = Provider<FilesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FilesRepository(dio);
});

class FilesRepository {
  final Dio _dio;

  FilesRepository(this._dio);

  Future<List<FileItemModel>> getFiles(String? path, {String? password}) async {
    try {
      final response = await _dio.get(
        '/Files',
        queryParameters: {
          if (path != null && path.isNotEmpty) 'path': path,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => FileItemModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load files: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching files: $e');
    }
  }

  Future<void> createFolder(String subPath, String folderName) async {
    try {
      await _dio.post('/Media/create-folder', data: {
        'subPath': subPath,
        'folderName': folderName,
      });
    } catch (e) {
      throw Exception('Lỗi tạo thư mục: $e');
    }
  }

  Future<void> deleteItem(String path) async {
    try {
      await _dio.delete('/Media/delete', queryParameters: {'path': path});
    } catch (e) {
      throw Exception('Lỗi xóa file: $e');
    }
  }

  Future<void> pinItem(String path) async {
    try {
      await _dio.post('/Files/pin', data: {'path': path});
    } catch (e) {
      throw Exception('Lỗi ghim file: $e');
    }
  }

  Future<void> unpinItem(String path) async {
    try {
      await _dio.post('/Files/unpin', data: {'path': path});
    } catch (e) {
      throw Exception('Lỗi bỏ ghim file: $e');
    }
  }

  Future<void> moveItem(String sourcePath, String targetFolder) async {
    try {
      await _dio.post('/Files/move', data: {
        'sourcePath': sourcePath,
        'targetFolder': targetFolder,
      });
    } catch (e) {
      throw Exception('Lỗi di chuyển file: $e');
    }
  }

  Future<void> uploadFile(String subPath, String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'subPath': subPath,
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      await _dio.post('/Media/upload', data: formData);
    } catch (e) {
      throw Exception('Lỗi tải file lên: $e');
    }
  }

  Future<void> downloadFile(String path, String savePath) async {
    try {
      await _dio.download('/Media/download?path=$path', savePath);
    } catch (e) {
      throw Exception('Lỗi tải file xuống: $e');
    }
  }
}


