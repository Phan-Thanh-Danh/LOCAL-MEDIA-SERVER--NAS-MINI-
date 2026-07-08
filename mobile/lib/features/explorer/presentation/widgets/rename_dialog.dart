import 'package:flutter/material.dart';

class RenameDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onConfirm;

  const RenameDialog({
    super.key,
    required this.currentName,
    required this.onConfirm,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi tên'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onConfirm(_controller.text);
            }
          },
          child: const Text('Đổi tên'),
        ),
      ],
    );
  }
}
