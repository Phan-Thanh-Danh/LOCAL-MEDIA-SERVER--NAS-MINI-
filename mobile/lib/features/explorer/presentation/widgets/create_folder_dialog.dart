import 'package:flutter/material.dart';

class CreateFolderDialog extends StatefulWidget {
  final Function(String) onConfirm;

  const CreateFolderDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo thư mục mới'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Tên thư mục',
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
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
