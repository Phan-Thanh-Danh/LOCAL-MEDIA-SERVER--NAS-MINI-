import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_type_helper.dart';
import '../../models/file_item.dart';
import 'media_thumbnail.dart';

class FileListItem extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const FileListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FileTypeHelper.getColorForType(item.type, item.isDirectory).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: (FileTypeHelper.isImage(item.name, item.type) || FileTypeHelper.isVideo(item.name, item.type))
                  ? MediaThumbnail(
                      item: item,
                      width: 48,
                      height: 48,
                      borderRadius: 12,
                      fallback: Icon(
                        FileTypeHelper.getIconForType(item.type, item.isDirectory),
                        color: FileTypeHelper.getColorForType(item.type, item.isDirectory),
                        size: 24,
                      ),
                    )
                  : Icon(
                      FileTypeHelper.getIconForType(item.type, item.isDirectory),
                      color: FileTypeHelper.getColorForType(item.type, item.isDirectory),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isHidden)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(LucideIcons.eyeOff, size: 14, color: AppColors.textSecondary),
                        ),
                      if (item.isLocked)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(LucideIcons.lock, size: 14, color: AppColors.warning),
                        ),
                      if (item.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(LucideIcons.pin, size: 14, color: AppColors.primary),
                        ),
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!item.isDirectory) ...[
                        Text(
                          item.sizeFormatted,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.type,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(LucideIcons.moreVertical, color: AppColors.textSecondary),
              onPressed: onMoreTap,
            ),
          ],
        ),
      ),
    );
  }
}
