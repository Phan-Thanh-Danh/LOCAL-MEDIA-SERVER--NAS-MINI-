import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/files_provider.dart';
import '../providers/file_actions_provider.dart';
import '../widgets/file_action_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thư mục mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên thư mục'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(fileActionsProvider).createFolder(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showVaultDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final vaultPassword = ref.read(vaultProvider);
    final isUnlocked = vaultPassword != null;

    if (isUnlocked) {
      ref.read(vaultProvider.notifier).lock();
      ref.invalidate(filesProvider); // Refresh to hide hidden files
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mở khóa Két Sắt'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nhập mật khẩu két sắt',
            prefixIcon: Icon(LucideIcons.lock),
          ),
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final pwd = controller.text;
              if (pwd.isNotEmpty) {
                ref.read(vaultProvider.notifier).unlock(pwd);
                ref.invalidate(filesProvider); // Refresh to fetch hidden files
                Navigator.pop(context);
              }
            },
            child: const Text('Mở khóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải file lên...')),
      );

      try {
        await ref.read(fileActionsProvider).uploadFile(path);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải file lên thành công!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi tải file lên: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentPathProvider);
    final filesAsyncValue = ref.watch(filesProvider);
    final isVaultUnlocked = ref.watch(vaultProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(LucideIcons.hardDrive, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('NAS Mini', style: Theme.of(context).appBarTheme.titleTextStyle),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isVaultUnlocked ? LucideIcons.eye : LucideIcons.eyeOff,
              color: isVaultUnlocked ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => _showVaultDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {
              // TODO: Implement Search
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (currentPath.isNotEmpty) {
                      ref.read(currentPathProvider.notifier).setPath('');
                    }
                  },
                  child: const Icon(LucideIcons.home, size: 18, color: AppColors.secondary),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentPath.isEmpty ? 'Home' : currentPath,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentPath.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final parts = currentPath.split('/');
                      if (parts.length > 1) {
                        parts.removeLast();
                        ref.read(currentPathProvider.notifier).setPath(parts.join('/'));
                      } else {
                        ref.read(currentPathProvider.notifier).setPath('');
                      }
                    },
                    child: const Icon(LucideIcons.arrowUpCircle, size: 18, color: AppColors.primary),
                  ),
              ],
            ),
          ),
          // File List
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: filesAsyncValue.when(
                data: (files) {
                  if (files.isEmpty) {
                    return Center(
                      child: Text(
                        'Thư mục trống',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      IconData icon;
                      Color iconColor = AppColors.secondary;
                      
                      if (file.isDirectory) {
                        icon = LucideIcons.folder;
                        iconColor = Colors.amber[600]!;
                      } else {
                        final ext = file.extension.toLowerCase();
                        if (['.mp4', '.mkv', '.avi', '.mov'].contains(ext)) {
                          icon = LucideIcons.clapperboard;
                        } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
                          icon = LucideIcons.image;
                        } else if (['.mp3', '.wav', '.flac'].contains(ext)) {
                          icon = LucideIcons.music;
                        } else {
                          icon = LucideIcons.file;
                        }
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: AppColors.splash,
                          highlightColor: AppColors.splash,
                          onTap: () {
                            if (file.isDirectory) {
                              ref.read(currentPathProvider.notifier).setPath(file.relativePath);
                            } else {
                              final ext = file.extension.toLowerCase();
                              String viewType = 'unknown';
                              if (['.mp4', '.mkv', '.avi', '.mov'].contains(ext)) {
                                viewType = 'video';
                              } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
                                viewType = 'image';
                              }
                              
                              if (viewType != 'unknown') {
                                // Provide actual URL later from media endpoint
                                context.push('/media', extra: {
                                  'title': file.name,
                                  'type': viewType,
                                  'url': Uri.encodeFull('http://192.168.2.10:5000/api/Media/$viewType/${file.relativePath}'),
                                  'relativePath': file.relativePath,
                                });
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Icon(icon, color: iconColor, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        file.isDirectory 
                                          ? 'Folder • ${file.lastModified.toLocal().toString().split(' ')[0]}'
                                          : '${file.lastModified.toLocal().toString().split(' ')[0]} • ${file.sizeFormatted}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.moreVertical, size: 20),
                                  color: AppColors.secondary,
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      builder: (context) => FileActionBottomSheet(file: file),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi khi tải dữ liệu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(filesProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'upload',
            onPressed: () => _uploadFile(context, ref),
            child: const Icon(LucideIcons.upload),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'newFolder',
            onPressed: () => _showCreateFolderDialog(context, ref),
            child: const Icon(LucideIcons.folderPlus),
          ),
        ],
      ),
    );
  }
}
