import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/files_provider.dart';
import '../providers/file_actions_provider.dart';
import '../widgets/file_action_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vault_provider.dart';
import '../providers/view_mode_provider.dart';

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

  Widget _buildFileIcon(BuildContext context, WidgetRef ref, dynamic file, double size) {
    IconData icon;
    Color color = AppColors.secondary;
    if (file.isDirectory) {
      icon = LucideIcons.folder;
      color = Colors.amber[600]!;
    } else {
      final ext = file.extension.toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
        final auth = ref.watch(authProvider);
        final vaultPass = ref.watch(vaultProvider);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: 'http://192.168.2.10:5000/api/Media/thumbnail/${file.relativePath}',
            httpHeaders: {
              if (auth.token != null) 'Authorization': 'Bearer ${auth.token}',
              if (vaultPass != null) 'Vault-Password': vaultPass,
            },
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: (c, u, e) => Icon(LucideIcons.image, size: size, color: AppColors.secondary),
          ),
        );
      } else if (['.mp4', '.mkv', '.avi', '.mov'].contains(ext)) {
        icon = LucideIcons.clapperboard;
      } else if (['.mp3', '.wav', '.flac'].contains(ext)) {
        icon = LucideIcons.music;
      } else {
        icon = LucideIcons.file;
      }
    }
    return Icon(icon, size: size, color: color);
  }

  Widget _buildListView(BuildContext context, WidgetRef ref, List<dynamic> files) {
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: _buildFileIcon(context, ref, file, 24),
          title: Text(file.name, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(file.isDirectory ? 'Folder' : file.sizeFormatted),
          onTap: () => _handleTap(context, ref, file),
          trailing: IconButton(
            icon: const Icon(LucideIcons.moreVertical, size: 20),
            onPressed: () => _showActions(context, file),
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref, List<dynamic> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return InkWell(
          onTap: () => _handleTap(context, ref, file),
          child: Column(
            children: [
              Expanded(child: _buildFileIcon(context, ref, file, 48)),
              const SizedBox(height: 4),
              Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, dynamic file) {
    if (file.isDirectory) {
      ref.read(currentPathProvider.notifier).setPath(file.relativePath);
    } else {
      final ext = file.extension.toLowerCase();
      String viewType = 'unknown';
      if (['.mp4', '.mkv', '.avi', '.mov'].contains(ext)) viewType = 'video';
      else if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) viewType = 'image';
      if (viewType != 'unknown') {
        context.push('/media', extra: {
          'title': file.name,
          'type': viewType,
          'url': Uri.encodeFull('http://192.168.2.10:5000/api/Media/$viewType/${file.relativePath}'),
          'relativePath': file.relativePath,
        });
      }
    }
  }

  void _showActions(BuildContext context, dynamic file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => FileActionBottomSheet(file: file),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentPathProvider);
    final filesAsyncValue = ref.watch(filesProvider);
    final viewMode = ref.watch(viewModeProvider);
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
            onPressed: () {},
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(currentPathProvider.notifier).setPath(''),
                  child: const Icon(LucideIcons.home, size: 18, color: AppColors.secondary),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(currentPath.isEmpty ? 'Home' : currentPath, overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: Icon(viewMode == ViewMode.list ? LucideIcons.layoutGrid : LucideIcons.list),
                  onPressed: () => ref.read(viewModeProvider.notifier).toggleMode(),
                ),
              ],
            ),
          ),
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
                  
                  return viewMode == ViewMode.list 
                    ? _buildListView(context, ref, files)
                    : _buildGridView(context, ref, files);
                },
                loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
