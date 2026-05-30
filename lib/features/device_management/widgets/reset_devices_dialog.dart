import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ResetDevicesDialog extends StatelessWidget {
  final String userName;
  final VoidCallback onConfirm;

  const ResetDevicesDialog(
      {super.key, required this.userName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة ضبط الأجهزة'),
      content: Text(
          'سيتم تسجيل الخروج من جميع أجهزة "$userName"، هل أنت متأكد؟',
          style: const TextStyle(height: 1.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white),
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
