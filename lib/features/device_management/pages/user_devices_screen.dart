// user_devices_screen.dart
// شاشة تعرض أجهزة المستخدم (المفعلة والتي بحاجة إلى تفعيل)

import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/device_management/controllers/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserDevicesScreen extends StatelessWidget {
  final dynamic userId;
  final String? userName;
  final String? userEmail;

  const UserDevicesScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ إنشاء الـ Provider هنا مباشرة (نفس أسلوب DeviceManagementPage)
    return ChangeNotifierProvider(
      create: (context) => DeviceManagementController()..loadAllData(),
      child: _UserDevicesContent(
        userId: userId,
        userName: userName,
        userEmail: userEmail,
      ),
    );
  }
}

class _UserDevicesContent extends StatefulWidget {
  final dynamic userId;
  final String? userName;
  final String? userEmail;

  const _UserDevicesContent({
    required this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  State<_UserDevicesContent> createState() => _UserDevicesContentState();
}

class _UserDevicesContentState extends State<_UserDevicesContent> {
  late Map<String, dynamic> _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // ✅ مراقبة التغييرات في الـ Controller
    final controller = context.read<DeviceManagementController>();

    // البحث عن المستخدم في قائمة المستخدمين
    final user = controller.usersWithDevices.firstWhere(
      (u) => u['id'].toString() == widget.userId.toString(),
      orElse: () => {},
    );

    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ مراقبة التغييرات في الـ Controller
    return Consumer<DeviceManagementController>(
      builder: (context, controller, child) {
        debugPrint('🔍 UserDevices Build - isLoading: ${controller.isLoading}');

        if (controller.isLoading || _isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // جلب أجهزة المستخدم
        final userDevices =
            _user['devices'] as List<Map<String, dynamic>>? ?? [];

        // تقسيم الأجهزة
        final approvedDevices = userDevices.where((device) {
          final isApproved =
              device['is_approved'] == true || device['approved'] == true;
          final isBlocked =
              device['is_blocked'] == true || device['blocked'] == true;
          return isApproved && !isBlocked;
        }).toList();

        final pendingDevices = userDevices.where((device) {
          final isApproved =
              device['is_approved'] == true || device['approved'] == true;
          final isBlocked =
              device['is_blocked'] == true || device['blocked'] == true;
          return !isApproved && !isBlocked;
        }).toList();

        final blockedDevices = userDevices.where((device) {
          final isBlocked =
              device['is_blocked'] == true || device['blocked'] == true;
          return isBlocked;
        }).toList();

        debugPrint(
            '📊 Devices - Approved: ${approvedDevices.length}, Pending: ${pendingDevices.length}, Blocked: ${blockedDevices.length}');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(widget.userName ?? 'أجهزة المستخدم'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await controller.refreshAll();
                  _loadUserData(); // إعادة تحميل بيانات المستخدم
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Header مميز
              SliverToBoxAdapter(
                child: _buildUserHeader(controller),
              ),

              // بطاقة الإحصائيات
              SliverToBoxAdapter(
                child: _buildStatsCard(
                    approvedDevices, pendingDevices, blockedDevices),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ⏳ أجهزة بحاجة إلى تفعيل (الأولوية القصوى)
              if (pendingDevices.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    '⏳ أجهزة بحاجة إلى تفعيل',
                    pendingDevices.length,
                    AppColors.warning,
                    Icons.pending_actions,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDeviceCard(
                      pendingDevices[index],
                      isPending: true,
                      controller: controller,
                    ),
                    childCount: pendingDevices.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // ✅ الأجهزة المفعلة
              if (approvedDevices.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    '✅ الأجهزة المفعلة',
                    approvedDevices.length,
                    AppColors.success,
                    Icons.devices,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDeviceCard(
                      approvedDevices[index],
                      isPending: false,
                      controller: controller,
                    ),
                    childCount: approvedDevices.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // 🚫 الأجهزة المحظورة
              if (blockedDevices.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    '🚫 الأجهزة المحظورة',
                    blockedDevices.length,
                    AppColors.error,
                    Icons.block,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDeviceCard(
                      blockedDevices[index],
                      isBlocked: true,
                      controller: controller,
                    ),
                    childCount: blockedDevices.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],

              // حالة عدم وجود أجهزة
              if (userDevices.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  // ✅ Header المستخدم
  Widget _buildUserHeader(DeviceManagementController controller) {
    final subscription = _user['subscription'] as Map<String, dynamic>?;
    final devicesSummary = _user['devices_summary'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Colors.purple.shade700,
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Text(
              widget.userName?.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.userName ?? 'مستخدم غير معروف',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.userEmail ?? 'بريد إلكتروني غير مسجل',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // معلومات الباقة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.subscriptions, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  subscription?['plan_type']?.toString().toUpperCase() ??
                      'BASIC',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  subscription?['status'] == 'active'
                      ? Icons.check_circle
                      : Icons.warning,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  subscription?['status'] == 'active' ? 'نشط' : 'غير نشط',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة الإحصائيات
  Widget _buildStatsCard(
    List<Map<String, dynamic>> approved,
    List<Map<String, dynamic>> pending,
    List<Map<String, dynamic>> blocked,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'المفعلة',
              count: approved.length,
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            _StatItem(
              label: 'بانتظار التفعيل',
              count: pending.length,
              icon: Icons.pending,
              color: AppColors.warning,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            _StatItem(
              label: 'محظورة',
              count: blocked.length,
              icon: Icons.block,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ عنوان القسم
  Widget _buildSectionHeader(
      String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة الجهاز
  Widget _buildDeviceCard(
    Map<String, dynamic> device, {
    bool isPending = false,
    bool isBlocked = false,
    required DeviceManagementController controller,
  }) {
    final isApproving = controller.isApproving == device['id'].toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPending
            ? BorderSide(color: AppColors.warning.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Container(
        decoration: isPending
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPending
                  ? AppColors.warning.withOpacity(0.1)
                  : isBlocked
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDeviceIcon(device),
              color: isPending
                  ? AppColors.warning
                  : isBlocked
                      ? AppColors.error
                      : AppColors.success,
              size: 28,
            ),
          ),
          title: Text(
            device['name'] ?? device['device_name'] ?? 'جهاز غير معروف',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'المعرف: ${device['id'] ?? 'غير معروف'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.grey,
                ),
              ),
              if (device['device_id'] != null &&
                  device['device_id'] != device['id'])
                Text(
                  'رقم الجهاز: ${device['device_id']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              if (device['device_type'] != null)
                Text(
                  'النوع: ${device['device_type']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              if (device['created_at'] != null)
                Text(
                  'تاريخ التسجيل: ${_formatDate(device['created_at'])}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'بانتظار التفعيل',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (isBlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'محظور',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (!isPending && !isBlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'مفعل',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPending)
                    _buildActionButton(
                      icon: Icons.check_circle,
                      color: AppColors.success,
                      onPressed: () => _approveDevice(device, controller),
                      isLoading: isApproving,
                      label: 'تفعيل',
                    ),
                  if (!isBlocked && !isPending)
                    _buildActionButton(
                      icon: Icons.block,
                      color: AppColors.warning,
                      onPressed: () => _blockDevice(device, controller),
                      label: 'حظر',
                    ),
                  _buildActionButton(
                    icon: Icons.delete,
                    color: AppColors.error,
                    onPressed: () => _deleteDevice(device, controller),
                    label: 'حذف',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ زر الإجراء
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
    String? label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: label ?? '',
        child: IconButton(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 18, color: color),
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }

  // ✅ حالة عدم وجود أجهزة
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_unknown_sharp,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أجهزة مسجلة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هذا المستخدم لم يقم بتسجيل أي أجهزة بعد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ أيقونة الجهاز حسب النوع
  IconData _getDeviceIcon(Map<String, dynamic> device) {
    final name = (device['name'] ?? device['device_name'] ?? '').toLowerCase();
    final type = (device['device_type'] ?? '').toLowerCase();

    if (name.contains('phone') ||
        name.contains('iphone') ||
        type.contains('mobile')) {
      return Icons.phone_android;
    } else if (name.contains('laptop') ||
        name.contains('macbook') ||
        type.contains('laptop')) {
      return Icons.laptop;
    } else if (name.contains('tablet') ||
        name.contains('ipad') ||
        type.contains('tablet')) {
      return Icons.tablet;
    }
    return Icons.devices;
  }

  // ✅ تنسيق التاريخ
  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'غير معروف';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.toString();
    }
  }

  // ✅ موافقة على جهاز
  Future<void> _approveDevice(Map<String, dynamic> device,
      DeviceManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفعيل الجهاز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('هل أنت متأكد من تفعيل هذا الجهاز؟'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المستخدم: ${widget.userName ?? 'مستخدم جديد'}'),
                  const SizedBox(height: 4),
                  Text('الجهاز: ${device['name'] ?? device['device_name']}'),
                  const SizedBox(height: 4),
                  Text('المعرف: ${device['id']}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('تفعيل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deviceId = device['id'];
    debugPrint('🔧 Approving device with ID: $deviceId');

    final success = await controller.approveDevice(deviceId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تفعيل الجهاز بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await controller.refreshAll();
      _loadUserData(); // تحديث البيانات
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ فشل تفعيل الجهاز'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ حظر جهاز
  Future<void> _blockDevice(Map<String, dynamic> device,
      DeviceManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر الجهاز'),
        content: const Text('هل أنت متأكد من حظر هذا الجهاز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('حظر'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.blockDevice(device['id']);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 تم حظر الجهاز بنجاح'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await controller.refreshAll();
      _loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ فشل حظر الجهاز'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ✅ حذف جهاز
  Future<void> _deleteDevice(Map<String, dynamic> device,
      DeviceManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الجهاز'),
        content: const Text(
            'هل أنت متأكد من حذف هذا الجهاز؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.deleteDevice(device['id']);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ تم حذف الجهاز بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await controller.refreshAll();
      _loadUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ فشل حذف الجهاز'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ✅ مكون الإحصائية المساعد
class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        TweenAnimationBuilder(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 500),
          builder: (context, int value, child) {
            return Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
