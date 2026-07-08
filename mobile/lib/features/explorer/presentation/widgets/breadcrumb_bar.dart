import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';

class BreadcrumbBar extends StatelessWidget {
  final String currentPath;
  final Function(String) onPathSelected;

  const BreadcrumbBar({
    super.key,
    required this.currentPath,
    required this.onPathSelected,
  });

  @override
  Widget build(BuildContext context) {
    final segments = currentPath.isEmpty ? [] : currentPath.split('/');
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: segments.length + 1, // +1 for root icon
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return IconButton(
              icon: const Icon(LucideIcons.home, size: 20),
              color: currentPath.isEmpty ? AppColors.textPrimary : AppColors.textSecondary,
              onPressed: () => onPathSelected(''),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          }
          
          final segment = segments[index - 1];
          final isLast = index == segments.length;
          
          // Build path for this segment
          final pathBuilder = segments.sublist(0, index).join('/');

          return InkWell(
            onTap: () => onPathSelected(pathBuilder),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                segment,
                style: TextStyle(
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  color: isLast ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
