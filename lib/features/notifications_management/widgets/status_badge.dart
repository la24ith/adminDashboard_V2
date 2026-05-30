import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class StatusBadge extends StatelessWidget {
  final NotificationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case NotificationStatus.scheduled:
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        text = 'مجدول';
        break;
      case NotificationStatus.sent:
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        text = 'مرسل';
        break;
      case NotificationStatus.expired:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        text = 'منتهي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
