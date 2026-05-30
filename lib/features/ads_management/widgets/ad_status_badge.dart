import 'package:flutter/material.dart';
import '../models/ad_model.dart';

class AdStatusBadge extends StatelessWidget {
  final AdStatus status;

  const AdStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String text;

    switch (status) {
      case AdStatus.active:
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        text = 'نشط';
        break;
      case AdStatus.inactive:
        color = const Color(0xFF94A3B8);
        bgColor = const Color(0xFFF1F5F9);
        text = 'غير نشط';
        break;
      case AdStatus.expired:
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        text = 'منتهي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
