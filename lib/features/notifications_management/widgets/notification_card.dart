import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../../../core/constants/app_colors.dart';

class NotificationCard extends StatefulWidget {
  // ✅ النوع الآن NotificationModel بدل Map خام
  final NotificationModel notification;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<bool> Function() onExtend;
  final Future<bool> Function() onSendNow;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onEdit,
    required this.onDelete,
    required this.onExtend,
    required this.onSendNow,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _isHovered = false;
  bool _isUpdating = false;

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ✅ الحالة تأتي من NotificationModel.status — لا منطق مكرر هنا
  String _getDateText(NotificationStatus status) {
    final n = widget.notification;
    if (status == NotificationStatus.scheduled && n.sendAt != null) {
      return '📅 مجدول: ${_formatDateTime(n.sendAt)}';
    } else if (n.sentAt != null) {
      return '📨 أرسل: ${_formatDateTime(n.sentAt)}';
    } else if (n.sendAt != null) {
      return '📅 موعد الإرسال: ${_formatDateTime(n.sendAt)}';
    }
    return '—';
  }

  Future<void> _handleSendNow() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final success = await widget.onSendNow();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ تم إرسال الإشعار بنجاح' : '❌ فشل إرسال الإشعار',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleExtend() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final success = await widget.onExtend();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ تم تمديد صلاحية الإشعار 7 أيام'
                : '❌ فشل تمديد الإشعار',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ✅ استخدام NotificationModel.status مباشرة
    final status = widget.notification.status;
    final isExpired = status == NotificationStatus.expired;
    final isScheduled = status == NotificationStatus.scheduled;
    final dateText = _getDateText(status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: _isHovered
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.08 : 0.04),
              blurRadius: _isHovered ? 16 : 12,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isExpired
                      ? AppColors.error
                      : (isScheduled ? AppColors.info : AppColors.success),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? AppColors.errorLight
                          : (isScheduled
                              ? AppColors.infoLight
                              : AppColors.successLight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isExpired
                                ? Icons.warning_amber_outlined
                                : (isScheduled
                                    ? Icons.schedule_outlined
                                    : Icons.check_circle_outline),
                            size: 24,
                            color: isExpired
                                ? AppColors.error
                                : (isScheduled
                                    ? AppColors.info
                                    : AppColors.success),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ وصول مباشر لخصائص النموذج — لا Map['key']
                        Text(
                          widget.notification.title.isEmpty
                              ? 'بدون عنوان'
                              : widget.notification.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: isScheduled
                                  ? AppColors.info
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isScheduled
                                      ? AppColors.info
                                      : AppColors.textTertiary,
                                  fontWeight: isScheduled
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isExpired
                                ? AppColors.errorLight
                                : (isScheduled
                                    ? AppColors.infoLight
                                    : AppColors.successLight),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isExpired
                                ? 'منتهي'
                                : (isScheduled ? 'مجدول' : 'مرسل'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? AppColors.error
                                  : (isScheduled
                                      ? AppColors.info
                                      : AppColors.success),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((_isHovered || isMobile) && !_isUpdating)
                    PopupMenuButton<String>(
                      icon:
                          Icon(Icons.more_vert, color: AppColors.textTertiary),
                      onSelected: _handleMenuAction,
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      itemBuilder: (context) => [
                        if (status != NotificationStatus.sent)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.info),
                                SizedBox(width: 12),
                                Text('تعديل الإشعار'),
                              ],
                            ),
                          ),
                        if (status == NotificationStatus.scheduled)
                          const PopupMenuItem(
                            value: 'send_now',
                            child: Row(
                              children: [
                                Icon(Icons.send,
                                    size: 18, color: AppColors.success),
                                SizedBox(width: 12),
                                Text('إرسال الآن'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'extend',
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 18, color: AppColors.warning),
                              SizedBox(width: 12),
                              Text('تمديد الصلاحية'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              SizedBox(width: 12),
                              Text('حذف الإشعار',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (_isUpdating)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String value) async {
    switch (value) {
      case 'edit':
        widget.onEdit();
        break;
      case 'send_now':
        await _handleSendNow();
        break;
      case 'extend':
        await _handleExtend();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الإشعار؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
