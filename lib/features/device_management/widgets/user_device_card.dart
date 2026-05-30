import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'device_item.dart';
import 'reset_devices_dialog.dart';

class UserDeviceCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onToggleDevice;
  final Function(Map<String, dynamic>) onResetDevices;

  const UserDeviceCard({
    super.key,
    required this.user,
    required this.onToggleDevice,
    required this.onResetDevices,
  });

  @override
  State<UserDeviceCard> createState() => _UserDeviceCardState();
}

class _UserDeviceCardState extends State<UserDeviceCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final devices = widget.user['devices'] ?? [];
    final activeDevices = devices
        .where((d) => d['is_approved'] == true && d['is_blocked'] != true)
        .length;
    final blockedDevices = devices.where((d) => d['is_blocked'] == true).length;
    final pendingDevices = devices
        .where((d) => d['is_approved'] == false && d['is_blocked'] != true)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: isSmallScreen
                ? _buildMobileHeader(
                    activeDevices, blockedDevices, pendingDevices)
                : _buildDesktopHeader(
                    activeDevices, blockedDevices, pendingDevices),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),

          // Devices List
          if (_isExpanded && devices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: devices.map<Widget>((device) {
                  return DeviceItem(
                    device: device,
                    onBlock: () => _handleToggleDevice(device),
                    onApprove: () => _handleToggleDevice(device),
                    onDelete: () => _handleDeleteDevice(device),
                  );
                }).toList(),
              ),
            ),
          if (_isExpanded && devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: Text('لا توجد أجهزة مسجلة',
                      style: TextStyle(color: AppColors.textTertiary))),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(
      int activeDevices, int blockedDevices, int pendingDevices) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(16)),
          child: Center(
              child: Text(
                  widget.user['name']?.isNotEmpty == true
                      ? widget.user['name'][0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 14),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.user['email'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildDeviceCountChip(
                      activeDevices, 'نشط', AppColors.success),
                  _buildDeviceCountChip(
                      blockedDevices, 'محظور', AppColors.error),
                  _buildDeviceCountChip(
                      pendingDevices, 'قيد الموافقة', AppColors.warning),
                ],
              ),
            ],
          ),
        ),

        // Actions
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showResetDialog(),
              icon: const Icon(Icons.device_unknown, size: 16),
              label: const Text('إعادة ضبط الأجهزة'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning),
                foregroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeader(
      int activeDevices, int blockedDevices, int pendingDevices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                  child: Text(
                      widget.user['name']?.isNotEmpty == true
                          ? widget.user['name'][0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.user['email'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildDeviceCountChip(activeDevices, 'نشط', AppColors.success),
            _buildDeviceCountChip(blockedDevices, 'محظور', AppColors.error),
            _buildDeviceCountChip(
                pendingDevices, 'قيد الموافقة', AppColors.warning),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showResetDialog(),
            icon: const Icon(Icons.device_unknown, size: 16),
            label: const Text('إعادة ضبط الأجهزة'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.warning),
              foregroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCountChip(int count, String label, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text('$count $label',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }

  void _handleToggleDevice(Map<String, dynamic> device) {
    widget.onToggleDevice(widget.user, device);
  }

  // ✅ دالة معالجة حذف الجهاز - معدلة بالكامل
  void _handleDeleteDevice(Map<String, dynamic> device) {
    _showDeleteConfirmation(device);
  }

  // ✅ عرض مربع حوار التأكيد مع التحقق من mounted
  void _showDeleteConfirmation(Map<String, dynamic> device) {
    // التحقق من أن الـ widget لا يزال مثبتاً
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الجهاز؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(dialogContext);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // ✅ إغلاق الـ Dialog أولاً
              if (mounted) Navigator.pop(dialogContext);
              // ✅ ثم تنفيذ الحذف بعد اكتمال الـ Dialog
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _confirmDelete(device);
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // ✅ تأكيد الحذف وتنفيذ العملية
  void _confirmDelete(Map<String, dynamic> device) {
    if (!mounted) return;
    widget.onToggleDevice(widget.user, device);
  }

  void _showResetDialog() {
    // ✅ التحقق من mounted قبل عرض الـ Dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => ResetDevicesDialog(
        userName: widget.user['name'] ?? 'المستخدم',
        onConfirm: () {
          if (mounted) Navigator.pop(context);
          if (mounted) widget.onResetDevices(widget.user);
        },
      ),
    );
  }
                  
                  
                  
                  
      }