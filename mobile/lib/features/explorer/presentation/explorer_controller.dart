import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/file_service.dart';
import '../../vault/data/vault_service.dart';
import '../models/file_item.dart';

enum FileFilterType { all, folder, video, image, other }
enum FileSortField { name, lastModified, size, type }
enum FileSortDirection { asc, desc }

class ExplorerState {
  final bool isLoading;
  final String? error;
  final List<FileItem> items;
  final String currentPath;
  final bool isVaultUnlocked;
  final FileItem? itemToMove;
  final Map<String, String> lockedFolderPasswords;
  final FileFilterType filterType;
  final FileSortField sortField;
  final FileSortDirection sortDirection;

  ExplorerState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.currentPath = '',
    this.isVaultUnlocked = false,
    this.itemToMove,
    this.lockedFolderPasswords = const {},
    this.filterType = FileFilterType.all,
    this.sortField = FileSortField.name,
    this.sortDirection = FileSortDirection.asc,
  });

  ExplorerState copyWith({
    bool? isLoading,
    String? error,
    List<FileItem>? items,
    String? currentPath,
    bool? isVaultUnlocked,
    FileItem? itemToMove,
    bool clearItemToMove = false,
    Map<String, String>? lockedFolderPasswords,
    FileFilterType? filterType,
    FileSortField? sortField,
    FileSortDirection? sortDirection,
  }) {
    return ExplorerState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Can be null to clear
      items: items ?? this.items,
      currentPath: currentPath ?? this.currentPath,
      isVaultUnlocked: isVaultUnlocked ?? this.isVaultUnlocked,
      itemToMove: clearItemToMove ? null : (itemToMove ?? this.itemToMove),
      lockedFolderPasswords: lockedFolderPasswords ?? this.lockedFolderPasswords,
      filterType: filterType ?? this.filterType,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

class ExplorerController extends Notifier<ExplorerState> {
  @override
  ExplorerState build() {
    Future.microtask(() => loadFiles(''));
    return ExplorerState();
  }

  FileService get _fileService => ref.read(fileServiceProvider);
  VaultService get _vaultService => ref.read(vaultServiceProvider);

  Future<void> loadFiles(String path) async {
    state = state.copyWith(isLoading: true, currentPath: path, error: null);
    try {
      final password = state.lockedFolderPasswords[path];
      final items = await _fileService.getFiles(path, password: password);
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadFiles(state.currentPath);
  }

  void navigateUp() {
    if (state.currentPath.isEmpty) return;
    
    final segments = state.currentPath.split('/');
    if (segments.length <= 1) {
      loadFiles('');
    } else {
      segments.removeLast();
      loadFiles(segments.join('/'));
    }
  }

  void navigateTo(String folderName) {
    if (state.currentPath.isEmpty) {
      loadFiles(folderName);
    } else {
      loadFiles('${state.currentPath}/$folderName');
    }
  }
  
  void navigateToPath(String path) {
    loadFiles(path);
  }

  Future<bool> unlockVault(String password) async {
    try {
      final items = await _fileService.getFiles(state.currentPath, password: password);
      _vaultService.setGlobalVaultPassword(password);
      state = state.copyWith(items: items, isVaultUnlocked: true, error: null);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unlockLockedFolder(String password) async {
    try {
      final items = await _fileService.getFiles(state.currentPath, password: password);
      final newMap = Map<String, String>.from(state.lockedFolderPasswords);
      newMap[state.currentPath] = password;
      state = state.copyWith(
        items: items, 
        lockedFolderPasswords: newMap, 
        error: null,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void lockVault() {
    _vaultService.setGlobalVaultPassword(null);
    state = state.copyWith(isVaultUnlocked: false);
    refresh();
  }

  void startMoveFlow(FileItem item) {
    state = state.copyWith(itemToMove: item);
  }

  void cancelMoveFlow() {
    state = state.copyWith(clearItemToMove: true);
  }

  Future<void> confirmMove() async {
    if (state.itemToMove == null) return;
    final item = state.itemToMove!;
    final targetFolder = state.currentPath;
    
    try {
      await _fileService.moveItem(item.relativePath, targetFolder);
      cancelMoveFlow();
      refresh();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setFilterType(FileFilterType type) {
    state = state.copyWith(filterType: type);
  }

  void setSortField(FileSortField field) {
    state = state.copyWith(sortField: field);
  }

  void toggleSortDirection() {
    state = state.copyWith(
      sortDirection: state.sortDirection == FileSortDirection.asc
          ? FileSortDirection.desc
          : FileSortDirection.asc,
    );
  }
}

final explorerControllerProvider = NotifierProvider<ExplorerController, ExplorerState>(
  ExplorerController.new,
);
