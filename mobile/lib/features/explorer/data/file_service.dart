import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/file_item.dart';

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(ApiClient.instance);
});

class FileService {
  final ApiClient _apiClient;

  FileService(this._apiClient);

  Future<List<FileItem>> getFiles(String? path, {String? password}) async {
    final Map<String, dynamic> query = {};
    if (path != null && path.isNotEmpty) {
      query['path'] = path;
    }
    if (password != null && password.isNotEmpty) {
      query['password'] = password;
    }

    final response = await _apiClient.get('/api/files', queryParameters: query);
    
    if (response != null) {
      return (response as List).map((json) => FileItem.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> createFolder(String folderName, String? subPath) async {
    await _apiClient.post(
      '/api/media/create-folder',
      data: {
        'folderName': folderName,
        'subPath': subPath ?? '',
      },
    );
  }

  Future<void> renameItem(String path, String newName) async {
    await _apiClient.post(
      '/api/media/rename',
      data: {
        'path': path,
        'newName': newName,
      },
    );
  }

  Future<void> deleteItem(String path) async {
    await _apiClient.post(
      '/api/media/delete',
      data: {
        'path': path,
      },
    );
  }

  Future<void> moveItem(String sourcePath, String targetFolder) async {
    await _apiClient.post(
      '/api/files/move',
      data: {
        'sourcePath': sourcePath,
        'targetFolder': targetFolder,
      },
    );
  }

  Future<void> uploadFile(String filePath, String fileName, String subPath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'subPath': subPath,
    });
    
    await _apiClient.post(
      '/api/media/upload',
      data: formData,
    );
  }
}
