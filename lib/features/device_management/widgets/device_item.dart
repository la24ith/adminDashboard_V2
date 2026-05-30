import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DeviceItem extends StatelessWidget {
  final Map<String, dynamic> device;
  final String? userName;
  final String? userEmail;
  final bool? isApproved;
  final VoidCallback? onBlock;
  final VoidCallback? onApprove;
  final VoidCallback? onDelete;

  const DeviceItem({
    super.key,
    required this.device,
    this.userName,
    this.userEmail,
    this.isApproved,
    this.onBlock,
    this.onApprove,
    this.onDelete,
  });

  String get statusText {
    if (device['is_blocked'] == true) return 'محظور';
    if (device['is_approved'] == true) return 'نشط';
    return 'قيد المراجعة';
  }

  Color get statusColor {
    if (device['is_blocked'] == true) return AppColors.error;
    if (device['is_approved'] == true) return AppColors.success;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: device['is_approved'] == false && device['is_blocked'] != true
            ? BorderSide(color: AppColors.warning.withOpacity(0.5), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ معلومات المستخدم (للمستخدمين الجدد)
            if (userName != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (userEmail != null)
                          Text(
                            userEmail!,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
            ],
            
            // ✅ معلومات الجهاز
            Row(
              children: [
                Icon(
                  Icons.devices,
                  size: 32,
                  color: statusColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['device_name'] ?? 'جهاز غير معروف',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device['device_type'] ?? 'نوع غير معروف',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // ✅ الأزرار
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onApprove != null && device['is_approved'] != true && device['is_blocked'] != true)
                  _buildActionButton(
                    icon: Icons.check_circle,
                    label: 'تفعيل',
                    color: AppColors.success,
                    onPressed: onApprove,
                  ),
                if (onBlock != null && device['is_blocked'] != true)
                  _buildActionButton(
                    icon: Icons.block,
                    label: 'حظر',
                    color: AppColors.error,
                    onPressed: onBlock,
                  ),
                if (onDelete != null)
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'حذف',
                    color: AppColors.textTertiary,
                    onPressed: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}