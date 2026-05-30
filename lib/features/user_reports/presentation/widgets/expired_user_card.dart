import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ExpiredUserCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const ExpiredUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                  user['name']?.isNotEmpty == true
                      ? user['name'][0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(user['email'] ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_busy,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('انتهى: ${_formatDate(user['subscription_end'])}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('منتهي',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '—';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '—';
    }
  }
}
