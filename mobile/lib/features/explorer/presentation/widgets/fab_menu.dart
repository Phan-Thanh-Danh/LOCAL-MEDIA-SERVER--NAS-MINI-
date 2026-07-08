import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';

class FabMenu extends StatelessWidget {
  final VoidCallback onCreateFolder;
  final VoidCallback onUploadFile;

  const FabMenu({
    super.key,
    required this.onCreateFolder,
    required this.onUploadFile,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.plus, color: Colors.white),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, -100),
      onSelected: (value) {
        if (value == 'folder') onCreateFolder();
        if (value == 'upload') onUploadFile();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'folder',
          child: Row(
            children: const [
              Icon(LucideIcons.folderPlus, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Tạo thư mục mới'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'upload',
          child: Row(
            children: const [
              Icon(LucideIcons.upload, color: AppColors.success),
              SizedBox(width: 12),
              Text('Tải file lên'),
            ],
          ),
        ),
      ],
    );
  }
}
