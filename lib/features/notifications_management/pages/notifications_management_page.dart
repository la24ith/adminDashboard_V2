import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_form_page.dart';
import '../../../core/constants/app_colors.dart';

class NotificationsManagementPage extends StatelessWidget {
  const NotificationsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationsController(),
      child: const _NotificationsPageContent(),
    );
  }
}

class _NotificationsPageContent extends StatefulWidget {
  const _NotificationsPageContent();

  @override
  State<_NotificationsPageContent> createState() =>
      _NotificationsPageContentState();
}

class _NotificationsPageContentState extends State<_NotificationsPageContent> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  // ✅ دالة تحديد حالة الإشعار (للفلتر)
  String _getNotificationStatus(Map<String, dynamic> notification) {
    final sendAt = notification['send_at'] != null
        ? DateTime.tryParse(notification['send_at'])
        : null;
    final sentAt = notification['sent_at'] != null
        ? DateTime.tryParse(notification['sent_at'])
        : null;
    final expiresAt = notification['expires_at'] != null
        ? DateTime.tryParse(notification['expires_at'])
        : null;
    final now = DateTime.now();

    if (sentAt != null) return 'sent';
    if (sendAt != null && sendAt.isAfter(now)) return 'scheduled';
    if (expiresAt != null && expiresAt.isBefore(now)) return 'expired';
    if (sendAt != null && sendAt.isBefore(now)) return 'sent';
    return 'sent';
  }

  List<Map<String, dynamic>> _getFilteredNotifications(
      List<Map<String, dynamic>> notifications) {
    return notifications.where((notification) {
      // ✅ البحث
      final matchesSearch = _searchQuery.isEmpty ||
          (notification['title']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (notification['message']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);

      // ✅ الفلتر حسب الحالة
      final status = _getNotificationStatus(notification);
      final matchesFilter = _filterStatus == 'all' || status == _filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();

    // عرض رسائل النجاح والخطأ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.successMessage != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        controller.clearMessages();
      }
      if (controller.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        controller.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إدارة الإشعارات',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.isActionInProgress
                          ? null
                          : () => _showNotificationForm(controller),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة إشعار'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'بحث عن إشعار...',
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: AppColors.textTertiary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('مجدول', 'scheduled'),
                      const SizedBox(width: 8),
                      _buildFilterChip('مرسل', 'sent'),
                      const SizedBox(width: 8),
                      _buildFilterChip('منتهي', 'expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredNotifications(controller.notifications).isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _getFilteredNotifications(controller.notifications).length,
                        itemBuilder: (context, index) {
                          final notification =
                              _getFilteredNotifications(controller.notifications)[index];
                          return NotificationCard(
                            notification: notification,
                            onEdit: () => _showNotificationForm(controller,
                                notification: notification),
                            onDelete: () => _deleteNotification(
                                context, controller, notification),
                            onExtend: () => _extendNotification(
                                context, controller, notification),
                            onSendNow: () => _sendNow(
                                context, controller, notification),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _filterStatus == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = filter),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent.withOpacity(0.1),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
              _searchQuery.isNotEmpty || _filterStatus != 'all'
                  ? 'لا توجد نتائج مطابقة للبحث'
                  : 'لا توجد إشعارات',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          if (_searchQuery.isNotEmpty || _filterStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterStatus = 'all';
                });
              },
              child: const Text('مسح الفلتر'),
            ),
        ],
      ),
    );
  }

  void _showNotificationForm(NotificationsController controller,
      {Map<String, dynamic>? notification}) {
    final isSent = notification != null &&
        (notification['sent_at'] != null ||
            (notification['send_at'] != null &&
                DateTime.parse(notification['send_at'])
                    .isBefore(DateTime.now())));

    if (isSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تعديل الإشعارات التي تم إرسالها بالفعل'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationFormPage(
          notification: notification,
          onSave: (notificationData) async {
            bool success;
            if (notification == null) {
              success = await controller.createNotification(notificationData);
            } else {
              success = await controller.updateNotification(
                  notification['id'].toString(), notificationData);
            }

            if (success && context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(notification == null
                      ? '✅ تم إضافة الإشعار بنجاح'
                      : '✅ تم تحديث الإشعار بنجاح'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
              await controller.loadNotifications();
            } else if (context.mounted && controller.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${controller.error!}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteNotification(BuildContext context,
      NotificationsController controller, Map<String, dynamic> notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الإشعار "${notification['title']}"؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.deleteNotification(notification['id'].toString());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حذف الإشعار بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل حذف الإشعار: ${controller.error ?? "حدث خطأ"}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<bool> _extendNotification(BuildContext context,
      NotificationsController controller, Map<String, dynamic> notification) async {
    final success = await controller.extendNotification(notification['id'].toString(), 7);
    if (success) {
      await controller.loadNotifications();
    }
    return success;
  }

  Future<bool> _sendNow(BuildContext context, NotificationsController controller,
      Map<String, dynamic> notification) async {
    final success = await controller.sendNow(notification['id'].toString());
    if (success) {
      await controller.loadNotifications();
    }
    return success;
  }
}