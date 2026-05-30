import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AchievedGoalCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const AchievedGoalCard({super.key, required this.user});

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
              gradient: const LinearGradient(
                  colors: [AppColors.success, AppColors.accent]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                  user['name']?.isNotEmpty == true
                      ? user['name'][0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white,
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
                Row(
                  children: [
                    const Icon(Icons.monitor_weight,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                        '${user['current_weight']?.toStringAsFixed(1) ?? '—'} كغ / ${user['target_weight']?.toStringAsFixed(1) ?? '—'} كغ',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
                if (user['weight_lost'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_down,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('خسر ${user['weight_lost'].toStringAsFixed(1)} كغ',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.success)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('تم تحقيق الهدف',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
