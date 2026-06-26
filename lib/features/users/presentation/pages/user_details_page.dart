// presentation/pages/user_details_page.dart

import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/users/presentation/controllers/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/users_controller.dart';
import '../widgets/user_form_page.dart';

class UserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailsPage({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ✅ متغير لتخزين أجهزة المستخدم
  List<Map<String, dynamic>> _userDevices = [];
  bool _isLoadingDevices = false;
  String? _deviceError;
  String? _processingDeviceId;

  // ✅ متغيرات للـ Controllers
  UsersController? _usersController;
  DeviceManagementController? _deviceController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // ✅ تأخير تحميل البيانات حتى يتم بناء الـ Widget بالكامل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ✅ دالة تهيئة الـ Controllers
  void _initializeControllers() {
    try {
      // محاولة الحصول على الـ Controllers من الـ Context
      _usersController = context.read<UsersController>();
      _deviceController = context.read<DeviceManagementController>();

      // تحميل أجهزة المستخدم
      _loadUserDevices();
    } catch (e) {
      // إذا لم يتم العثور على الـ Providers، نعرض رسالة خطأ
      setState(() {
        _deviceError = 'تعذر تحميل البيانات. يرجى المحاولة مرة أخرى.';
        _isLoadingDevices = false;
      });

      // طباعة الخطأ للتشخيص
      debugPrint('❌ Error initializing controllers: $e');
    }
  }

  // ✅ دالة تحميل أجهزة المستخدم
  Future<void> _loadUserDevices() async {
    if (_deviceController == null) {
      setState(() {
        _deviceError = 'تعذر تحميل الأجهزة. يرجى المحاولة مرة أخرى.';
      });
      return;
    }

    final userId = widget.user['id'].toString();

    setState(() {
      _isLoadingDevices = true;
      _deviceError = null;
    });

    try {
      await _deviceController!.loadUserDevices(userId);
      setState(() {
        _userDevices = _deviceController!.currentUserDevices;
        _isLoadingDevices = false;
      });
    } catch (e) {
      setState(() {
        _deviceError = 'فشل تحميل الأجهزة: $e';
        _isLoadingDevices = false;
      });
    }
  }

  // ✅ دالة للحصول على UsersController بأمان
  UsersController _getUsersController() {
    if (_usersController == null) {
      throw Exception('UsersController not initialized');
    }
    return _usersController!;
  }

  // ✅ دالة للحصول على DeviceManagementController بأمان
  DeviceManagementController _getDeviceController() {
    if (_deviceController == null) {
      throw Exception('DeviceManagementController not initialized');
    }
    return _deviceController!;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isActive = user['is_active'] ?? false;
    final isExpired = user['is_expired'] ?? false;
    final daysRemaining = user['days_remaining'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          user['name'] ?? 'تفاصيل المستخدم',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
            onPressed: () => _showEditUserDialog(context, user),
            tooltip: 'تعديل المستخدم',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.info),
            onPressed: () => _refreshAllData(),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 1. بطاقة المستخدم الرئيسية
              _buildUserHeaderCard(user, isActive),

              const SizedBox(height: 16),

              // ✅ 2. إحصائيات سريعة
              _buildQuickStats(user),

              const SizedBox(height: 16),

              // ✅ 3. معلومات الاشتراك (مع زر تعديل)
              _buildSubscriptionCard(user),

              const SizedBox(height: 16),
              _buildPermissionsCard(user),

              const SizedBox(height: 16),
              // ✅ 4. بيانات الأجهزة (مع device_id وأزرار تحكم)
              _buildDevicesCard(),

              const SizedBox(height: 16),

              // ✅ 5. معلومات إضافية
              _buildAdditionalInfo(user),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ بطاقة المستخدم الرئيسية
  Widget _buildUserHeaderCard(Map<String, dynamic> user, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppColors.accent, AppColors.accent.withOpacity(0.7)]
              : [AppColors.warning, AppColors.warning.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.accent : AppColors.warning)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    user['name']?.isNotEmpty == true
                        ? user['name'][0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'غير معروف',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildStatusChip(
                          isActive ? 'نشط' : 'موقوف',
                          isActive ? AppColors.success : AppColors.warning,
                          Colors.white,
                        ),
                        _buildStatusChip(
                          user['role'] == 'admin'
                              ? 'مدير'
                              : user['role'] == 'supervisor'
                                  ? 'مشرف'
                                  : 'مريض',
                          AppColors.info,
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user['is_expired'] ?? false
                            ? Icons.cancel_outlined
                            : user['days_remaining'] <= 7
                                ? Icons.warning_amber_outlined
                                : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user['is_expired'] ?? false
                            ? 'الاشتراك منتهي'
                            : user['days_remaining'] <= 7
                                ? 'ينتهي قريباً (${user['days_remaining']} يوم)'
                                : 'الاشتراك نشط (${user['days_remaining']} يوم متبقي)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ إحصائيات سريعة
  Widget _buildQuickStats(Map<String, dynamic> user) {
    final devicesUsed = user['devices_used'] ?? 0;
    final maxDevices = user['max_devices'] ?? 1;
    final devicesRemaining = user['devices_remaining'] ?? 0;
    final totalDevices = user['total_devices'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الأجهزة المستخدمة',
            '$devicesUsed / $maxDevices',
            Icons.devices,
            AppColors.info,
            progress: maxDevices > 0 ? devicesUsed / maxDevices : 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'الأجهزة المتبقية',
            '$devicesRemaining',
            Icons.devices_other,
            devicesRemaining > 0 ? AppColors.success : AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'إجمالي الأجهزة',
            '$totalDevices',
            Icons.smartphone,
            AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    double? progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceVariant,
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ بطاقة الاشتراك (مع زر تعديل)
  Widget _buildSubscriptionCard(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.subscriptions, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'معلومات الاشتراك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showEditSubscriptionDialog(context, user),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('تعديل'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('نوع الخطة', _translatePlanType(user['plan_type'])),
          _buildInfoRow(
              'الحالة', _translateStatus(user['subscription_status'])),
          _buildInfoRow('تاريخ البداية', user['subscription_start'] ?? '—'),
          _buildInfoRow('تاريخ النهاية', user['subscription_end'] ?? '—'),
          _buildInfoRow('السعر', '${user['price'] ?? 0} ريال'),
          _buildInfoRow('الأجهزة المسموحة', '${user['max_devices'] ?? 1} جهاز'),
          _buildInfoRow(
            'الأجهزة المتعددة',
            (user['is_multi_device'] ?? false) ? 'مفعل ✅' : 'غير مفعل ❌',
          ),
          // ✅ زر تمديد الاشتراك
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showExtendDialog(context, user),
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('تمديد الاشتراك'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بطاقة الأجهزة
  Widget _buildDevicesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.devices, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              const Text(
                'الأجهزة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoadingDevices)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${_userDevices.length} أجهزة',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const Divider(height: 24),

          // ✅ حالة التحميل
          if (_isLoadingDevices)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري تحميل الأجهزة...'),
                  ],
                ),
              ),
            )
          // ✅ حالة الخطأ
          else if (_deviceError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _deviceError!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadUserDevices,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          // ✅ قائمة الأجهزة
          else if (_userDevices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'لا توجد أجهزة مسجلة لهذا المستخدم',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userDevices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = _userDevices[index];
                return _buildDeviceItemWithControls(device);
              },
            ),
        ],
      ),
    );
  }

  // ✅ عنصر جهاز مع أزرار تحكم
  Widget _buildDeviceItemWithControls(Map<String, dynamic> device) {
    final deviceId = device['id']?.toString() ?? '';
    final isApproved = device['is_approved'] ?? false;
    final isBlocked = device['is_blocked'] ?? false;
    final isProcessing = _processingDeviceId == deviceId;

    // تحديد الحالة
    Color statusColor;
    String statusText;
    if (isBlocked) {
      statusColor = AppColors.error;
      statusText = 'محظور';
    } else if (isApproved) {
      statusColor = AppColors.success;
      statusText = 'موافق';
    } else {
      statusColor = AppColors.warning;
      statusText = 'معلق';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.smartphone : Icons.smartphone_outlined,
                color: isApproved ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ عرض device_id
                    Row(
                      children: [
                        const Text(
                          'Device ID: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            deviceId.isNotEmpty ? deviceId : 'غير معروف',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (device['device_name'] != null &&
                        device['device_name']!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        device['device_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // ✅ حالة الجهاز
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ✅ أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // زر الموافقة
              if (!isApproved && !isBlocked)
                _buildActionButton(
                  onPressed:
                      isProcessing ? null : () => _approveDevice(deviceId),
                  icon: Icons.check_circle_outline,
                  label: 'موافقة',
                  color: AppColors.success,
                  isLoading: isProcessing,
                ),
              if (!isApproved && !isBlocked) const SizedBox(width: 8),
              // زر الحظر
              if (!isBlocked)
                _buildActionButton(
                  onPressed: isProcessing ? null : () => _blockDevice(deviceId),
                  icon: Icons.block_outlined,
                  label: 'حظر',
                  color: AppColors.error,
                  isLoading: isProcessing,
                ),
              if (!isBlocked) const SizedBox(width: 8),
              // زر الحذف
              _buildActionButton(
                onPressed: isProcessing ? null : () => _deleteDevice(deviceId),
                icon: Icons.delete_outline,
                label: 'حذف',
                color: AppColors.error,
                isLoading: isProcessing,
                isDanger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ زر تحكم مساعد
  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
    bool isDanger = false,
  }) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDanger ? color : color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ✅ دوال التحكم بالأجهزة
  Future<void> _approveDevice(String deviceId) async {
    try {
      final controller = _getDeviceController();
      setState(() => _processingDeviceId = deviceId);

      final success = await controller.approveDevice(deviceId);

      setState(() => _processingDeviceId = null);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت الموافقة على الجهاز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadUserDevices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'فشل الموافقة على الجهاز'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _processingDeviceId = null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _blockDevice(String deviceId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الحظر'),
          content: const Text('هل أنت متأكد من حظر هذا الجهاز؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حظر'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final controller = _getDeviceController();
      setState(() => _processingDeviceId = deviceId);

      final success = await controller.blockDevice(deviceId);

      setState(() => _processingDeviceId = null);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حظر الجهاز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadUserDevices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'فشل حظر الجهاز'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _processingDeviceId = null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذا الجهاز؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final controller = _getDeviceController();
      setState(() => _processingDeviceId = deviceId);

      final success = await controller.deleteDevice(deviceId);

      setState(() => _processingDeviceId = null);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الجهاز بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
          await _loadUserDevices();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'فشل حذف الجهاز'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _processingDeviceId = null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ تحديث جميع البيانات
  Future<void> _refreshAllData() async {
    try {
      final controller = _getUsersController();
      await controller.refreshUserData(widget.user['id'].toString());
      await _loadUserDevices();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث جميع البيانات'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ دوال الاشتراك
  void _showExtendDialog(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id'].toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمديد الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                      'تاريخ النهاية الحالي: ${_formatDate(user['subscription_end'])}'),
                  const SizedBox(height: 4),
                  Text('المتبقي: ${user['days_remaining'] ?? 0} يوم',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _extendSubscription(context, userId, 30),
                    child: const Text('+30 يوم'))),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _extendSubscription(context, userId, 90),
                    child: const Text('+90 يوم'))),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => _extendSubscription(context, userId, 365),
                    child: const Text('+365 يوم'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'))
        ],
      ),
    );
  }

  Future<void> _extendSubscription(
      BuildContext context, String userId, int days) async {
    Navigator.pop(context);

    try {
      final controller = _getUsersController();
      final success = await controller.extendSubscription(userId, days);

      if (context.mounted) {
        if (success) {
          await controller.refreshUserData(userId);
          await _loadUserDevices();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم تمديد الاشتراك $days يوماً'),
              backgroundColor: AppColors.success));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(controller.error ?? 'فشل تمديد الاشتراك'),
              backgroundColor: AppColors.error));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ تعديل المستخدم
  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    try {
      final controller = _getUsersController();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserFormPage(
            user: user,
            onSave: (userData) async {
              final success = await controller.updateUser(
                user['id'].toString(),
                userData,
              );
              if (!success) {
                throw Exception(controller.error ?? 'فشل تحديث المستخدم');
              }
              return true;
            },
          ),
        ),
      ).then((result) {
        if (result == true) {
          _refreshAllData();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ تعديل الاشتراك
  void _showEditSubscriptionDialog(
      BuildContext context, Map<String, dynamic> user) {
    try {
      final controller = _getUsersController();
      final userId = user['id'].toString();
      final startDateController = TextEditingController(
          text: user['subscription_start'] ??
              DateTime.now().toIso8601String().split('T')[0]);
      final endDateController = TextEditingController(
          text: user['subscription_end'] ??
              DateTime.now()
                  .add(const Duration(days: 30))
                  .toIso8601String()
                  .split('T')[0]);
      final planTypeController =
          TextEditingController(text: user['plan_type'] ?? 'monthly');
      final priceController =
          TextEditingController(text: user['price']?.toString() ?? '199.99');
      final maxDevicesController =
          TextEditingController(text: user['max_devices']?.toString() ?? '1');
      String status = user['subscription_status'] ?? 'active';

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('تعديل الاشتراك'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: startDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ البداية',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.parse(startDateController.text),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            startDateController.text =
                                date.toIso8601String().split('T')[0];
                            setStateDialog(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ النهاية',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(endDateController.text),
                            firstDate: DateTime.parse(startDateController.text),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            endDateController.text =
                                date.toIso8601String().split('T')[0];
                            setStateDialog(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: planTypeController.text,
                        decoration: const InputDecoration(
                          labelText: 'نوع الخطة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'monthly', child: Text('شهري')),
                          DropdownMenuItem(
                              value: 'quarterly', child: Text('ربع سنوي')),
                          DropdownMenuItem(
                              value: 'yearly', child: Text('سنوي')),
                        ],
                        onChanged: (value) {
                          planTypeController.text = value!;
                          setStateDialog(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'الحالة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('نشط')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('غير نشط')),
                          DropdownMenuItem(
                              value: 'expired', child: Text('منتهي')),
                        ],
                        onChanged: (value) {
                          status = value!;
                          setStateDialog(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: maxDevicesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد الأجهزة المسموحة',
                          prefixIcon: Icon(Icons.devices),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    final success = await controller.updateSubscription(
                      userId,
                      {
                        'start_date': startDateController.text,
                        'end_date': endDateController.text,
                        'plan_type': planTypeController.text,
                        'status': status,
                        'price': double.parse(priceController.text),
                        'max_devices': int.parse(maxDevicesController.text),
                      },
                    );

                    if (context.mounted) {
                      if (success) {
                        await controller.refreshUserData(userId);
                        await _loadUserDevices();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث الاشتراك بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text(controller.error ?? 'فشل تحديث الاشتراك'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ✅ دوال مساعدة
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null || dateValue == '—') return '—';
    try {
      final date = DateTime.parse(dateValue);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  String _translatePlanType(String? planType) {
    switch (planType) {
      case 'monthly':
        return 'شهري';
      case 'quarterly':
        return 'ربع سنوي';
      case 'yearly':
        return 'سنوي';
      default:
        return planType ?? 'غير محدد';
    }
  }

  String _translateStatus(String? status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'inactive':
        return 'غير نشط';
      case 'expired':
        return 'منتهي';
      default:
        return status ?? 'غير محدد';
    }
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'معلومات إضافية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('المعرف (ID)', '${user['id'] ?? '—'}'),
          _buildInfoRow('الدور', _translateRole(user['role'])),
          _buildInfoRow('رقم الهاتف', user['phone'] ?? '—'),
          _buildInfoRow('شريحة المستخدم', user['patient_segment'] ?? '—'),
          if (user['created_by'] != null)
            _buildInfoRow('تم الإنشاء بواسطة', '${user['created_by']}'),
        ],
      ),
    );
  }

  String _translateRole(String? role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'supervisor':
        return 'مشرف';
      case 'patient':
        return 'مريض';
      default:
        return role ?? 'غير محدد';
    }
  }

  Widget _buildPermissionsCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] ?? false;
    final isMultiDevice = user['is_multi_device'] ?? false;
    final canScreenshot = user['can_screenshot'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── العنوان ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Text(
                'الصلاحيات والتحكم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          // ── تفعيل الحساب ──
          _buildToggleRow(
            icon: Icons.person_outline,
            iconColor: isActive ? AppColors.success : AppColors.error,
            label: 'تفعيل الحساب',
            subtitle: isActive ? 'الحساب نشط' : 'الحساب موقوف',
            value: isActive,
            onChanged: (val) => _toggleStatus(user),
          ),

          const Divider(height: 16),

          // ── الأجهزة المتعددة ──
          _buildToggleRow(
            icon: Icons.devices_outlined,
            iconColor: isMultiDevice ? AppColors.info : AppColors.textSecondary,
            label: 'الأجهزة المتعددة',
            subtitle: isMultiDevice ? 'مسموح بأجهزة متعددة' : 'جهاز واحد فقط',
            value: isMultiDevice,
            onChanged: (val) => _toggleMultiDevice(user),
          ),

          const Divider(height: 16),

          // ── تصوير الشاشة ──
          _buildToggleRow(
            icon: Icons.screenshot_outlined,
            iconColor:
                canScreenshot ? AppColors.warning : AppColors.textSecondary,
            label: 'تصوير الشاشة',
            subtitle: canScreenshot
                ? 'مسموح للمستخدم بتصوير الشاشة'
                : 'ممنوع تصوير الشاشة',
            value: canScreenshot,
            onChanged: (val) => _toggleScreenshot(user),
          ),
        ],
      ),
    );
  }

// ── Widget مساعد للـ Toggle ──
  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
        ),
      ],
    );
  }

// ── دوال التحكم ──
  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final controller = _getUsersController();
    final success = await controller.toggleUserStatus(
      user['id'].toString(),
      user['is_active'] ?? false,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? controller.successMessage ?? 'تم التحديث'
            : controller.error ?? 'فشل التحديث'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
      if (success) await _refreshAllData();
    }
  }

  Future<void> _toggleMultiDevice(Map<String, dynamic> user) async {
    final controller = _getUsersController();
    final success = await controller.toggleMultiDevice(
      user['id'].toString(),
      user['is_multi_device'] ?? false,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? controller.successMessage ?? 'تم التحديث'
            : controller.error ?? 'فشل التحديث'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
      if (success) await _refreshAllData();
    }
  }

  Future<void> _toggleScreenshot(Map<String, dynamic> user) async {
    final controller = _getUsersController();
    final success = await controller.toggleScreenshot(
      user['id'].toString(),
      user['can_screenshot'] ?? false,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? controller.successMessage ?? 'تم التحديث'
            : controller.error ?? 'فشل التحديث'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
      if (success) await _refreshAllData();
    }
  }
}
