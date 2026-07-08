import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/file_item.dart';

class FileActionSheet extends StatelessWidget {
  final FileItem item;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onMove;
  final VoidCallback onDownload;
  final VoidCallback onPinToggle;
  final VoidCallback onVaultToggle;

  const FileActionSheet({
    super.key,
    required this.item,
    required this.onRename,
    required this.onDelete,
    required this.onMove,
    required this.onDownload,
    required this.onPinToggle,
    required this.onVaultToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.displaySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (!item.isDirectory)
            ListTile(
              leading: const Icon(LucideIcons.download, color: AppColors.primary),
              title: const Text('Tải xuống'),
              onTap: onDownload,
            ),
          ListTile(
            leading: Icon(item.isPinned ? LucideIcons.pinOff : LucideIcons.pin, color: AppColors.primary),
            title: Text(item.isPinned ? 'Bỏ ghim' : 'Ghim'),
            onTap: onPinToggle,
          ),
          ListTile(
            leading: const Icon(LucideIcons.folderInput, color: AppColors.info),
            title: const Text('Di chuyển'),
            onTap: onMove,
          ),
          ListTile(
            leading: const Icon(LucideIcons.edit2, color: AppColors.warning),
            title: const Text('Đổi tên'),
            onTap: onRename,
          ),
          if (item.isDirectory)
            ListTile(
              leading: Icon(item.isHidden ? LucideIcons.eye : LucideIcons.eyeOff, color: AppColors.secondary),
              title: Text(item.isHidden ? 'Bỏ ẩn thư mục' : 'Ẩn thư mục'),
              onTap: onVaultToggle,
            ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: AppColors.error),
            title: const Text('Xóa', style: TextStyle(color: AppColors.error)),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
