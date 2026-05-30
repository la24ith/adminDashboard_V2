import 'package:admin_dashboard/features/posts/data/models/post_form_data.dart';
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final PostStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case PostStatus.published:
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        text = 'منشور';
        break;
      case PostStatus.scheduled:
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFDBEAFE);
        text = 'مجدول';
        break;
      case PostStatus.draft:
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        text = 'مسودة';
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
