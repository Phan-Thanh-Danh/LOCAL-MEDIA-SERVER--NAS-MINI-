import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final String itemName;
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({
    super.key,
    required this.itemName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận xóa'),
      content: Text('Bạn có chắc chắn muốn xóa "$itemName" không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
