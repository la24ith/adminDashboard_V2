import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;

  const ConfirmDialog({
    required this.title,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // ✅ يرجع true فقط
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
