import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/file_item_model.dart';
import '../../data/repositories/files_repository.dart';

// Provides the current directory path (empty means root)
class CurrentPathNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setPath(String path) {
    state = path;
  }
}

final currentPathProvider = NotifierProvider<CurrentPathNotifier, String>(CurrentPathNotifier.new);

// Fetches the files for the current path
final filesProvider = FutureProvider<List<FileItemModel>>((ref) async {
  final path = ref.watch(currentPathProvider);
  final repository = ref.watch(filesRepositoryProvider);
  return repository.getFiles(path);
});
