import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/files_repository.dart';
import 'files_provider.dart';

final fileActionsProvider = Provider<FileActions>((ref) {
  return FileActions(ref);
});

class FileActions {
  final Ref _ref;
  
  FileActions(this._ref);

  FilesRepository get _repo => _ref.read(filesRepositoryProvider);

  Future<void> createFolder(String folderName) async {
    final currentPath = _ref.read(currentPathProvider);
    await _repo.createFolder(currentPath, folderName);
    _ref.invalidate(filesProvider);
  }

  Future<void> deleteItem(String path) async {
    await _repo.deleteItem(path);
    _ref.invalidate(filesProvider);
  }

  Future<void> pinItem(String path) async {
    await _repo.pinItem(path);
    _ref.invalidate(filesProvider);
  }

  Future<void> unpinItem(String path) async {
    await _repo.unpinItem(path);
    _ref.invalidate(filesProvider);
  }

  Future<void> moveItem(String sourcePath, String targetFolder) async {
    await _repo.moveItem(sourcePath, targetFolder);
    _ref.invalidate(filesProvider);
  }

  Future<void> uploadFile(String filePath) async {
    final currentPath = _ref.read(currentPathProvider);
    await _repo.uploadFile(currentPath, filePath);
    _ref.invalidate(filesProvider);
  }

  Future<void> downloadFile(String path, String savePath) async {
    await _repo.downloadFile(path, savePath);
  }
}

