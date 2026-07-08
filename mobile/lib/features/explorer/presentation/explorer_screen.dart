import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
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
import '../../../core/storage/secure_storage_service.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  bool _isGridView = false;

  void _onItemTap(dynamic item, ExplorerController controller) {
    if (item.isDirectory) {
      if (item.isLocked && !ref.read(explorerControllerProvider).isVaultUnlocked) {
        _showUnlockVaultDialog(item.relativePath);
      } else {
        controller.navigateToPath(item.relativePath);
      }
    } else {
      context.push('/media-preview', extra: item);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Media Server'),
        actions: [
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
                        child: state.items.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: const Center(
                                      child: Text('Thư mục trống', style: TextStyle(color: AppColors.textSecondary)),
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
                                    itemCount: state.items.length,
                                    itemBuilder: (context, index) {
                                      final item = state.items[index];
                                      return FileGridItem(
                                        item: item,
                                        onTap: () => _onItemTap(item, controller),
                                        onMoreTap: () => _showFileActions(item),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    itemCount: state.items.length,
                                    itemBuilder: (context, index) {
                                      final item = state.items[index];
                                      return FileListItem(
                                        item: item,
                                        onTap: () => _onItemTap(item, controller),
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
