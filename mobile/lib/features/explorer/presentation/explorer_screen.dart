import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/file_item.dart';
import 'explorer_controller.dart';
import 'widgets/file_list_item.dart';
import 'widgets/file_grid_item.dart';
import 'widgets/breadcrumb_bar.dart';
import 'widgets/file_action_sheet.dart';
import 'widgets/rename_dialog.dart';
import 'widgets/create_folder_dialog.dart';
import 'widgets/delete_confirm_dialog.dart';
import 'widgets/fab_menu.dart';
import '../../vault/presentation/vault_dialogs.dart';
import '../data/file_service.dart';
import '../data/pinned_item_service.dart';
import '../../vault/data/vault_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/utils/download_helper.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  bool _isGridView = false;

  List<FileItem> _getFilteredAndSortedItems(
    List<FileItem> items, 
    FileFilterType filterType,
    FileSortField sortField,
    FileSortDirection sortDirection,
  ) {
    // 1. Filter
    var result = items.where((item) {
      if (filterType == FileFilterType.all) return true;
      if (filterType == FileFilterType.folder) return item.isDirectory;
      
      final ext = item.name.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext);
      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
      
      if (filterType == FileFilterType.video) return !item.isDirectory && isVideo;
      if (filterType == FileFilterType.image) return !item.isDirectory && isImage;
      if (filterType == FileFilterType.other) return !item.isDirectory && !isVideo && !isImage;
      
      return true;
    }).toList();

    // 2. Sort
    result.sort((a, b) {
      if ((sortField == FileSortField.name || sortField == FileSortField.type) && a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }

      int comparison = 0;
      switch (sortField) {
        case FileSortField.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case FileSortField.lastModified:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case FileSortField.size:
          comparison = a.size.compareTo(b.size);
          break;
        case FileSortField.type:
          final extA = a.isDirectory ? '' : a.name.split('.').last.toLowerCase();
          final extB = b.isDirectory ? '' : b.name.split('.').last.toLowerCase();
          comparison = extA.compareTo(extB);
          if (comparison == 0) {
            comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          break;
      }
      return sortDirection == FileSortDirection.asc ? comparison : -comparison;
    });

    return result;
  }

  void _onItemTap(dynamic item, ExplorerController controller, List<FileItem> currentItems) {
    if (item.isDirectory) {
      if (item.isLocked && !ref.read(explorerControllerProvider).isVaultUnlocked) {
        _showUnlockVaultDialog(item.relativePath);
      } else {
        controller.navigateToPath(item.relativePath);
      }
    } else {
      final items = currentItems.where((i) => !i.isDirectory).toList();
      final initialIndex = items.indexWhere((i) => i.relativePath == item.relativePath);
      context.push('/media-preview', extra: {
        'items': items,
        'initialIndex': initialIndex >= 0 ? initialIndex : 0,
      });
    }
  }

  void _showUnlockVaultDialog(String folderPath) {
    showDialog(
      context: context,
      builder: (context) => VaultPasswordDialog(
        onConfirm: (password) async {
          final controller = ref.read(explorerControllerProvider.notifier);
          final success = await controller.unlockVault(password);
          if (success && mounted) {
            controller.navigateToPath(folderPath);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mật khẩu không chính xác')),
            );
          }
        },
      ),
    );
  }

  void _showFileActions(dynamic item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FileActionSheet(
        item: item,
        onRename: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => RenameDialog(
              currentName: item.name,
              onConfirm: (newName) async {
                try {
                  await ref.read(fileServiceProvider).renameItem(item.relativePath, newName);
                  ref.read(explorerControllerProvider.notifier).refresh();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          );
        },
        onDelete: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => DeleteConfirmDialog(
              itemName: item.name,
              onConfirm: () async {
                try {
                  await ref.read(fileServiceProvider).deleteItem(item.relativePath);
                  ref.read(explorerControllerProvider.notifier).refresh();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          );
        },
        onMove: () {
          Navigator.pop(context);
          ref.read(explorerControllerProvider.notifier).startMoveFlow(item);
        },
        onDownload: () async {
          Navigator.pop(context);
          final storage = SecureStorageService();
          final token = await storage.getToken();
          final baseUrl = await storage.getBaseUrl();
          if (mounted) {
            DownloadHelper.downloadAndShareOrOpen(
              context,
              item.relativePath,
              item.name,
              token,
              baseUrl,
            );
          }
        },
        onPinToggle: () async {
          Navigator.pop(context);
          try {
            if (item.isPinned) {
              await ref.read(pinnedItemServiceProvider).unpinItem(item.relativePath);
            } else {
              await ref.read(pinnedItemServiceProvider).pinItem(item.relativePath);
            }
            ref.read(explorerControllerProvider.notifier).refresh();
          } catch (e) {}
        },
        onVaultToggle: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => VaultPasswordDialog(
              onConfirm: (password) async {
                try {
                  if (item.isHidden) {
                    await ref.read(vaultServiceProvider).unhideFolder(item.relativePath, password);
                  } else {
                    await ref.read(vaultServiceProvider).hideFolder(item.relativePath, password);
                  }
                  ref.read(explorerControllerProvider.notifier).refresh();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          );
        },
        onLockToggle: () {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => VaultPasswordDialog(
              onConfirm: (password) async {
                try {
                  if (item.isLocked) {
                    await ref.read(vaultServiceProvider).unlockFolder(item.relativePath, password);
                  } else {
                    await ref.read(vaultServiceProvider).lockFolder(item.relativePath, password);
                  }
                  ref.read(explorerControllerProvider.notifier).refresh();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(item.isLocked ? 'Đã mở khóa thư mục' : 'Đã khóa thư mục')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleUpload() async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null && result.files.single.path != null) {
      final currentPath = ref.read(explorerControllerProvider).currentPath;
      try {
        await ref.read(fileServiceProvider).uploadFile(
          result.files.single.path!,
          result.files.single.name,
          currentPath,
        );
        ref.read(explorerControllerProvider.notifier).refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explorerControllerProvider);
    final controller = ref.read(explorerControllerProvider.notifier);
    final filteredItems = _getFilteredAndSortedItems(state.items, state.filterType, state.sortField, state.sortDirection);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Media Server'),
        actions: [
          PopupMenuButton<dynamic>(
            icon: Icon(
              LucideIcons.sliders,
              color: state.filterType != FileFilterType.all || state.sortField != FileSortField.name || state.sortDirection != FileSortDirection.asc 
                  ? AppColors.primary 
                  : AppColors.textPrimary,
            ),
            onSelected: (value) {
               if (value is FileFilterType) {
                 controller.setFilterType(value);
               } else if (value is FileSortField) {
                 controller.setSortField(value);
               } else if (value is FileSortDirection) {
                 if (state.sortDirection != value) controller.toggleSortDirection();
               }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(enabled: false, child: Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
              PopupMenuItem(value: FileSortField.name, child: Text(state.sortField == FileSortField.name ? '✓  Tên' : '     Tên')),
              PopupMenuItem(value: FileSortField.lastModified, child: Text(state.sortField == FileSortField.lastModified ? '✓  Ngày sửa' : '     Ngày sửa')),
              PopupMenuItem(value: FileSortField.size, child: Text(state.sortField == FileSortField.size ? '✓  Kích thước' : '     Kích thước')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text('Thứ tự', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
              PopupMenuItem(value: FileSortDirection.asc, child: Text(state.sortDirection == FileSortDirection.asc ? '✓  Tăng dần' : '     Tăng dần')),
              PopupMenuItem(value: FileSortDirection.desc, child: Text(state.sortDirection == FileSortDirection.desc ? '✓  Giảm dần' : '     Giảm dần')),
              const PopupMenuDivider(),
              const PopupMenuItem(enabled: false, child: Text('Lọc loại file', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
              PopupMenuItem(value: FileFilterType.all, child: Text(state.filterType == FileFilterType.all ? '✓  Tất cả' : '     Tất cả')),
              PopupMenuItem(value: FileFilterType.folder, child: Text(state.filterType == FileFilterType.folder ? '✓  Thư mục' : '     Thư mục')),
              PopupMenuItem(value: FileFilterType.video, child: Text(state.filterType == FileFilterType.video ? '✓  Video' : '     Video')),
              PopupMenuItem(value: FileFilterType.image, child: Text(state.filterType == FileFilterType.image ? '✓  Hình ảnh' : '     Hình ảnh')),
              PopupMenuItem(value: FileFilterType.other, child: Text(state.filterType == FileFilterType.other ? '✓  Khác' : '     Khác')),
            ],
          ),
          IconButton(
            icon: Icon(
              state.isVaultUnlocked ? LucideIcons.unlock : LucideIcons.lock,
              color: state.isVaultUnlocked ? AppColors.success : AppColors.textPrimary,
            ),
            onPressed: () {
              if (state.isVaultUnlocked) {
                controller.lockVault();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã khóa Két Sắt')),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => VaultPasswordDialog(
                    onConfirm: (password) async {
                      final success = await controller.unlockVault(password);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã mở khóa Két Sắt')),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mật khẩu không chính xác')),
                        );
                      }
                    },
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? LucideIcons.list : LucideIcons.grid),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(LucideIcons.layoutDashboard),
            onPressed: () => context.push('/dashboard'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final storage = SecureStorageService();
                await storage.deleteToken();
                if (mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          BreadcrumbBar(
            currentPath: state.currentPath,
            onPathSelected: (path) => controller.navigateToPath(path),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: state.error!.contains('LOCKED')
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.lock, size: 64, color: AppColors.warning),
                                  const SizedBox(height: 16),
                                  const Text('Thư mục này đã bị khóa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(LucideIcons.key),
                                    label: const Text('Nhập mật khẩu'),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => VaultPasswordDialog(
                                          onConfirm: (password) async {
                                            final success = await controller.unlockLockedFolder(password);
                                            if (!success && mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Mật khẩu không chính xác')),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                                  const SizedBox(height: 16),
                                  Text(state.error!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => controller.refresh(),
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.refresh,
                        child: filteredItems.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: Center(
                                      child: Text(
                                        state.items.isEmpty ? 'Thư mục trống' : 'Không có tập tin nào khớp với bộ lọc', 
                                        style: const TextStyle(color: AppColors.textSecondary)
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _isGridView
                                ? GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredItems[index];
                                      return FileGridItem(
                                        item: item,
                                        onTap: () => _onItemTap(item, controller, filteredItems),
                                        onMoreTap: () => _showFileActions(item),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredItems[index];
                                      return FileListItem(
                                        item: item,
                                        onTap: () => _onItemTap(item, controller, filteredItems),
                                        onMoreTap: () => _showFileActions(item),
                                      );
                                    },
                                  ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: state.itemToMove != null
          ? BottomAppBar(
              color: AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => controller.cancelMoveFlow(),
                    icon: const Icon(LucideIcons.x, color: AppColors.error),
                    label: const Text('Hủy', style: TextStyle(color: AppColors.error)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => controller.confirmMove(),
                    icon: const Icon(LucideIcons.folderInput),
                    label: const Text('Chuyển đến đây'),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: state.itemToMove != null
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: FabMenu(
                onCreateFolder: () {
                  showDialog(
                    context: context,
                    builder: (context) => CreateFolderDialog(
                      onConfirm: (folderName) async {
                        final currentPath = ref.read(explorerControllerProvider).currentPath;
                        try {
                          await ref.read(fileServiceProvider).createFolder(folderName, currentPath);
                          ref.read(explorerControllerProvider.notifier).refresh();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        }
                      },
                    ),
                  );
                },
                onUploadFile: _handleUpload,
              ),
            ),
    );
  }
}
