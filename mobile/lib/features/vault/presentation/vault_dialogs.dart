import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VaultPasswordDialog extends StatefulWidget {
  final bool isSettingNew;
  final Function(String) onConfirm;

  const VaultPasswordDialog({
    super.key,
    this.isSettingNew = false,
    required this.onConfirm,
  });

  @override
  State<VaultPasswordDialog> createState() => _VaultPasswordDialogState();
}

class _VaultPasswordDialogState extends State<VaultPasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isSettingNew ? 'Tạo mật khẩu Két Sắt' : 'Nhập mật khẩu Két Sắt'),
      content: TextField(
        controller: _passwordController,
        autofocus: true,
        obscureText: _obscureText,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: 'Mật khẩu',
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? LucideIcons.eyeOff : LucideIcons.eye),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onConfirm(_passwordController.text);
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
