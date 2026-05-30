// lib/features/posts/presentation/widgets/post_header_section.dart
import 'package:admin_dashboard/features/posts/presentation/widgets/post_status_chip.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';

class PostHeaderSection extends StatelessWidget {
  final bool isEditing;
  final PostStatus status;
  final Function(PostStatus) onStatusChanged;
  final VoidCallback onCancel;

  const PostHeaderSection({
    super.key,
    required this.isEditing,
    required this.status,
    required this.onStatusChanged,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8),
        child: GestureDetector(
          onTap: onCancel,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'تعديل المنشور' : 'منشور جديد',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PostStatusChip(
                  status: status,
                  onChanged: onStatusChanged,
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusHint(status),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        expandedTitleScale: 1.1,
      ),
    );
  }

  String _getStatusHint(PostStatus status) {
    switch (status) {
      case PostStatus.published:
        return 'المنشور مرئي للجميع';
      case PostStatus.scheduled:
        return 'سينشر تلقائياً في الوقت المحدد';
      case PostStatus.draft:
        return 'مسودة غير مرئية للجمهور';
    }
  }
}
