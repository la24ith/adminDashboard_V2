// lib/features/posts/presentation/widgets/post_status_chip.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';

class PostStatusChip extends StatelessWidget {
  final PostStatus status;
  final Function(PostStatus)? onChanged;

  const PostStatusChip({
    super.key,
    required this.status,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (onChanged == null) {
      return _buildChip(
          status, _getStatusColor(status), _getStatusIcon(status), false);
    }

    return PopupMenuButton<PostStatus>(
      offset: const Offset(0, 40),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onChanged,
      child: _buildChip(
          status, _getStatusColor(status), _getStatusIcon(status), true),
      itemBuilder: (context) => [
        _buildMenuItem(
            PostStatus.draft, 'مسودة', Icons.edit_note, AppColors.warning),
        _buildMenuItem(
            PostStatus.published, 'منشور', Icons.public, AppColors.success),
        _buildMenuItem(
            PostStatus.scheduled, 'مجدول', Icons.schedule, AppColors.info),
      ],
    );
  }

  Widget _buildChip(
      PostStatus status, Color color, IconData icon, bool isInteractive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status.arabicName,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          if (isInteractive) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: color),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<PostStatus> _buildMenuItem(
      PostStatus status, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Color _getStatusColor(PostStatus status) {
    switch (status) {
      case PostStatus.published:
        return AppColors.success;
      case PostStatus.scheduled:
        return AppColors.info;
      case PostStatus.draft:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(PostStatus status) {
    switch (status) {
      case PostStatus.published:
        return Icons.check_circle;
      case PostStatus.scheduled:
        return Icons.schedule;
      case PostStatus.draft:
        return Icons.edit_note;
    }
  }
}
