import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/device_management/controllers/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/device_item.dart';

class DeviceManagementPage extends StatelessWidget {
  const DeviceManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ إنشاء الـ Provider هنا مباشرة
    return ChangeNotifierProvider(
      create: (context) => DeviceManagementController()..loadAllData(),
      child: const _DeviceManagementContent(),
    );
  }
}

class _DeviceManagementContent extends StatefulWidget {
  const _DeviceManagementContent();

  @override
  State<_DeviceManagementContent> createState() => _DeviceManagementContentState();
}

class _DeviceManagementContentState extends State<_DeviceManagementContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ مراقبة التغييرات في الـ Controller
    final controller = context.watch<DeviceManagementController>();
    
    // ✅ طباعة حالة التحميل للتأكد
    debugPrint('🔍 Build called - isLoading: ${controller.isLoading}, devices count: ${controller.allDevices.length}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الأجهزة'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📱 جميع الأجهزة'),
            Tab(text: '✅ أجهزة نشطة'),
            Tab(text: '⏳ بانتظار الموافقة'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAll(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllDevicesTab(controller),
          _buildApprovedDevicesTab(controller),
          _buildPendingDevicesTab(controller),
        ],
      ),
    );
  }

  // ✅ علامة تبويب الأجهزة المنتظرة
  Widget _buildPendingDevicesTab(DeviceManagementController controller) {
    // ✅ طباعة للتأكد من البيانات
    debugPrint('📱 Pending devices count: ${controller.pendingDevices.length}');
    
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(controller.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refreshAll(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final pendingDevices = controller.pendingDevices;

    if (pendingDevices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 16),
            Text('لا توجد أجهزة بانتظار الموافقة'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingDevices.length,
        itemBuilder: (context, index) {
          final device = pendingDevices[index];
          final user = controller.getUserForDevice(device);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?['name'] ?? 'مستخدم جديد',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?['email'] ?? device['device_id'] ?? 'بريد إلكتروني غير معروف',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: controller.isApproving == device['id']
                              ? null
                              : () => _handleApproveDevice(context, controller, device, user),
                          icon: controller.isApproving == device['id']
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle, size: 16),
                          label: Text(controller.isApproving == device['id'] ? 'جاري التفعيل...' : 'تفعيل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.devices, 'الجهاز', device['device_name'] ?? 'غير معروف'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.info_outline, 'النوع', device['device_type'] ?? 'غير معروف'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.fingerprint, 'المعرف', device['device_id'] ?? 'غير معروف'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, 'التسجيل', _formatDate(device['created_at'])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ علامة تبويب جميع الأجهزة
  Widget _buildAllDevicesTab(DeviceManagementController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(child: Text('خطأ: ${controller.error}'));
    }

    final devices = controller.allDevices;

    if (devices.isEmpty) {
      return const Center(child: Text('لا توجد أجهزة مسجلة'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final user = controller.getUserForDevice(device);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DeviceItem(
              device: device,
              userName: user?['name'],
              userEmail: user?['email'],
              onBlock: () => _handleBlockDevice(context, controller, device),
              onApprove: () => _handleApproveDevice(context, controller, device, user),
              onDelete: () => _handleDeleteDevice(context, controller, device),
            ),
          );
        },
      ),
    );
  }

  // ✅ علامة تبويب الأجهزة النشطة
  Widget _buildApprovedDevicesTab(DeviceManagementController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final approvedDevices = controller.approvedDevices;

    if (approvedDevices.isEmpty) {
      return const Center(child: Text('لا توجد أجهزة نشطة'));
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: approvedDevices.length,
        itemBuilder: (context, index) {
          final device = approvedDevices[index];
          final user = controller.getUserForDevice(device);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DeviceItem(
              device: device,
              userName: user?['name'],
              userEmail: user?['email'],
              isApproved: true,
              onBlock: () => _handleBlockDevice(context, controller, device),
              onApprove: null,
              onDelete: () => _handleDeleteDevice(context, controller, device),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير معروف';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

// ✅ معالجة الموافقة على الجهاز
Future<void> _handleApproveDevice(
  BuildContext context,
  DeviceManagementController controller,
  Map<String, dynamic> device,
  Map<String, dynamic>? user,
) async {
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
                Text('المستخدم: ${user?['name'] ?? 'مستخدم جديد'}'),
                const SizedBox(height: 4),
                Text('البريد: ${user?['email'] ?? device['device_id']}'),
                const SizedBox(height: 4),
                Text('الجهاز: ${device['device_name']}'),
                // ✅ طباعة الـ id للتأكد
                Text('ID: ${device['id']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
            backgroundColor: Colors.green,
          ),
          child: const Text('تفعيل'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  
  // ✅ device['id'] يمكن أن يكون int أو String - الدالة تتعامل مع الاثنين
  final deviceId = device['id'];
  debugPrint('🔧 Approving device with ID: $deviceId (type: ${deviceId.runtimeType})');
  
  final success = await controller.approveDevice(deviceId);
  
  if (!context.mounted) return;

  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تفعيل الجهاز بنجاح'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    await controller.refreshAll();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('فشل تفعيل الجهاز'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
  Future<void> _handleBlockDevice(BuildContext context, DeviceManagementController controller, Map<String, dynamic> device) async {
    await controller.blockDevice(device['id']);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحظر')));
  }

  Future<void> _handleDeleteDevice(BuildContext context, DeviceManagementController controller, Map<String, dynamic> device) async {
    await controller.deleteDevice(device['id']);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
  }
}