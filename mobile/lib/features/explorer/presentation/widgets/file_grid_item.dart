import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/file_type_helper.dart';
import '../../models/file_item.dart';
import 'media_thumbnail.dart';

class FileGridItem extends ConsumerWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const FileGridItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: (FileTypeHelper.isImage(item.name, item.type) || FileTypeHelper.isVideo(item.name, item.type))
                    ? MediaThumbnail(
                        item: item,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 0,
                        fallback: _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!item.isDirectory)
                          Text(
                            item.sizeFormatted,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onMoreTap,
                    child: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: FileTypeHelper.getColorForType(item.type, item.isDirectory).withAlpha(25),
      child: Center(
        child: Icon(
          FileTypeHelper.getIconForType(item.type, item.isDirectory),
          color: FileTypeHelper.getColorForType(item.type, item.isDirectory),
          size: 32,
        ),
      ),
    );
  }
}
