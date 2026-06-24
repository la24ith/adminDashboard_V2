// presentation/pages/subscription_edit_page.dart

import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/users_controller.dart';

class SubscriptionEditPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final UsersController controller;

  const SubscriptionEditPage({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  State<SubscriptionEditPage> createState() => _SubscriptionEditPageState();
}

class _SubscriptionEditPageState extends State<SubscriptionEditPage> {
  late TextEditingController startDateController;
  late TextEditingController endDateController;
  late TextEditingController planTypeController;
  late TextEditingController maxDevicesController;
  String status = 'active';
  bool _isLoading = false;
  late double price;

  @override
  void initState() {
    super.initState();
    final user = widget.user;

    startDateController = TextEditingController(
      text: user['subscription_start'] != null
          ? user['subscription_start']
          : DateTime.now().toIso8601String().split('T')[0],
    );
    endDateController = TextEditingController(
      text: user['subscription_end'] != null
          ? user['subscription_end']
          : DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0],
    );
    planTypeController = TextEditingController(
      text: user['plan_type'] ?? 'monthly',
    );
    maxDevicesController = TextEditingController(
      text: user['max_devices']?.toString() ?? '1',
    );
    status = user['subscription_status'] ?? 'active';
    price = user['price']?.toDouble() ?? 199.99;
  }

  @override
  void dispose() {
    startDateController.dispose();
    endDateController.dispose();
    planTypeController.dispose();
    maxDevicesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isMobile),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ بطاقة معلومات المستخدم
                _buildUserInfoCard(isMobile),
                const SizedBox(height: 24),

                // ✅ بطاقة تعديل الاشتراك
                _buildSubscriptionForm(isMobile),
                const SizedBox(height: 24),

                // ✅ أزرار الإجراءات
                _buildActionButtons(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ AppBar مخصص
  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        tooltip: 'رجوع',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.subscriptions,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعديل الاشتراك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.user['name'] ?? 'مستخدم غير معروف',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (!isMobile)
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            label: const Text('إلغاء'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
          ),
      ],
    );
  }

  // ✅ بطاقة معلومات المستخدم
  Widget _buildUserInfoCard(bool isMobile) {
    final user = widget.user;
    final isActive = user['is_active'] ?? false;
    final daysRemaining = user['days_remaining'] ?? 0;
    final isExpired = user['is_expired'] ?? false;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isActive ? AppColors.success : AppColors.warning,
            isActive
                ? AppColors.success.withOpacity(0.8)
                : AppColors.warning.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.success : AppColors.warning)
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
              // ✅ Avatar
              Container(
                width: 56,
                height: 56,
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
                      fontSize: 24,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildStatusChip(
                          isActive ? 'نشط' : 'موقوف',
                          isActive ? Colors.green : Colors.orange,
                        ),
                        _buildStatusChip(
                          isExpired ? 'منتهي' : '${daysRemaining} يوم متبقي',
                          isExpired ? Colors.red : Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ نموذج تعديل الاشتراك
  Widget _buildSubscriptionForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ عنوان القسم
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_note,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'بيانات الاشتراك',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // ✅ الحقول
          // حقل تاريخ البداية
          _buildModernTextField(
            controller: startDateController,
            label: 'تاريخ البداية',
            icon: Icons.calendar_today,
            readOnly: true,
            isMobile: isMobile,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(startDateController.text),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale('ar', 'SA'),
              );
              if (date != null) {
                startDateController.text = date.toIso8601String().split('T')[0];
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),

          // حقل تاريخ النهاية
          _buildModernTextField(
            controller: endDateController,
            label: 'تاريخ النهاية',
            icon: Icons.event_busy,
            readOnly: true,
            isMobile: isMobile,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(endDateController.text),
                firstDate: DateTime.parse(startDateController.text),
                lastDate: DateTime(2030),
                locale: const Locale('ar', 'SA'),
              );
              if (date != null) {
                endDateController.text = date.toIso8601String().split('T')[0];
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 16),

          // نوع الخطة
          _buildModernDropdown(
            value: planTypeController.text,
            label: 'نوع الخطة',
            icon: Icons.agriculture,
            isMobile: isMobile,
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('شهري')),
              DropdownMenuItem(value: 'quarterly', child: Text('ربع سنوي')),
              DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
            ],
            onChanged: (value) {
              planTypeController.text = value!;
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // حالة الاشتراك
          _buildModernDropdown(
            value: status,
            label: 'حالة الاشتراك',
            icon: Icons.circle,
            isMobile: isMobile,
            items: const [
              DropdownMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('نشط'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'inactive',
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Text('غير نشط'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'expired',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('منتهي'),
                  ],
                ),
              ),
            ],
            onChanged: (value) {
              status = value!;
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // عدد الأجهزة المسموحة
          _buildModernTextField(
            controller: maxDevicesController,
            label: 'عدد الأجهزة المسموحة',
            icon: Icons.devices,
            keyboardType: TextInputType.number,
            suffix: 'جهاز',
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),

          // ✅ عرض السعر بشكل ثابت
        ],
      ),
    );
  }

  // ✅ بطاقة السعر الثابت

  // ✅ أزرار الإجراءات
  Widget _buildActionButtons(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isMobile ? 'حفظ' : 'حفظ التغييرات',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دوال مساعدة للتصميم

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? suffix,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: isMobile ? 10 : 12),
                child: Icon(
                  icon,
                  size: isMobile ? 18 : 20,
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  readOnly: readOnly,
                  keyboardType: keyboardType,
                  onTap: onTap,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: isMobile ? 12 : 14,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: EdgeInsets.only(right: isMobile ? 10 : 12),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: isMobile ? 12 : 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown<T>({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(left: isMobile ? 10 : 12),
                child: Icon(
                  icon,
                  size: isMobile ? 18 : 20,
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<T>(
                    value: value as T,
                    items: items,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.black87,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade500,
                    ),
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ حفظ البيانات
  Future<void> _saveSubscription() async {
    setState(() => _isLoading = true);

    try {
      final success = await widget.controller.updateSubscription(
        widget.user['id'].toString(),
        {
          'start_date': startDateController.text,
          'end_date': endDateController.text,
          'plan_type': planTypeController.text,
          'status': status,
          'price': price,
          'max_devices': int.parse(maxDevicesController.text),
        },
      );

      if (mounted) {
        if (success) {
          await widget.controller.refreshUserData(widget.user['id'].toString());
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              'تم تحديث الاشتراك بنجاح',
              AppColors.success,
              Icons.check_circle,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              widget.controller.error ?? 'فشل تحديث الاشتراك',
              AppColors.error,
              Icons.error_outline,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            e.toString(),
            AppColors.error,
            Icons.error_outline,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  SnackBar _buildSnackBar(String message, Color color, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }
}
