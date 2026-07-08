import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/file_item_model.dart';
import '../providers/file_actions_provider.dart';

class FileActionBottomSheet extends ConsumerWidget {
  final FileItemModel file;

  const FileActionBottomSheet({super.key, required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  file.isDirectory ? LucideIcons.folder : LucideIcons.file,
                  color: file.isDirectory ? Colors.amber : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (!file.isPinned)
            ListTile(
              leading: const Icon(LucideIcons.pin),
              title: const Text('Ghim lên đầu'),
              onTap: () {
                ref.read(fileActionsProvider).pinItem(file.relativePath);
                Navigator.pop(context);
              },
            )
          else
            ListTile(
              leading: const Icon(LucideIcons.pinOff),
              title: const Text('Bỏ ghim'),
              onTap: () {
                ref.read(fileActionsProvider).unpinItem(file.relativePath);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading: const Icon(LucideIcons.move),
            title: const Text('Di chuyển'),
            onTap: () {
              // TODO: Implement move dialog
              Navigator.pop(context);
            },
          ),
          if (!file.isDirectory)
            ListTile(
              leading: const Icon(LucideIcons.download),
              title: const Text('Tải xuống'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final dir = await getApplicationDocumentsDirectory(); // Or another path
                  final savePath = '${dir.path}/${file.name}';
                  await ref.read(fileActionsProvider).downloadFile(file.relativePath, savePath);
                } catch (e) {
                  // Ignore for now
                }
              },
            ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.red),
            title: const Text('Xóa', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(fileActionsProvider).deleteItem(file.relativePath);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
