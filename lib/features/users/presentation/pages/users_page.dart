// presentation/pages/users_page.dart

import 'dart:async';

import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/core/di/setup_locator.dart';
import 'package:admin_dashboard/features/device_management/controllers/device_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/users_controller.dart';
import '../widgets/user_card.dart';
import '../widgets/user_form_page.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => sl<UsersController>(),
      child: const _UsersPageContent(),
    );
  }
}

class _UsersPageContent extends StatefulWidget {
  const _UsersPageContent();

  @override
  State<_UsersPageContent> createState() => _UsersPageContentState();
}

class _UsersPageContentState extends State<_UsersPageContent> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  final ScrollController _scrollController = ScrollController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final controller = context.read<UsersController>();
      if (!controller.isLoadingMore &&
          controller.hasMore &&
          !controller.isLoading) {
        controller.loadMoreUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UsersController>();
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 4;
    if (screenWidth < 1200) crossAxisCount = 3;
    if (screenWidth < 900) crossAxisCount = 2;
    if (screenWidth < 600) crossAxisCount = 1;

    // عرض رسائل النجاح والخطأ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.successMessage != null && !controller.isDeleting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(controller.successMessage!)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        controller.clearMessages();
      }

      if (controller.error != null && !controller.isDeleting) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'خطأ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  controller.error!,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        controller.clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
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
                        const Text('إدارة المستخدمين',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        ElevatedButton.icon(
                          onPressed: controller.isActionInProgress
                              ? null
                              : () => _showUserForm(context, controller),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة مستخدم'),
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
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _searchTimer?.cancel();
                        _searchTimer =
                            Timer(const Duration(milliseconds: 500), () {
                          controller.searchUsers(value);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'بحث عن مستخدم...',
                        prefixIcon: Icon(Icons.search,
                            size: 20, color: AppColors.textTertiary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    size: 20, color: AppColors.textTertiary),
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  controller.searchUsers('');
                                },
                              )
                            : null,
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
                          _buildFilterChip('الكل', 'all', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip('نشط', 'active', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip('منتهي', 'expired', controller),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              'ينتهي قريباً', 'expiring', controller),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users Grid
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : controller.users.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: controller.users.length +
                                (controller.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              // عرض مؤشر تحميل في آخر القائمة
                              if (index >= controller.users.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              final user = controller.users[index];
                              final isDeletingThisUser =
                                  controller.isDeleting &&
                                      controller.deletingUserId ==
                                          user['id'].toString();
                              return UserCard(
                                user: user,
                                onEdit: () => _showUserForm(context, controller,
                                    user: user),
                                onExtend: () => _showExtendDialog(
                                    context, controller, user),
                                onEditSubscription: () =>
                                    _showEditSubscriptionDialog(
                                        context, controller, user),
                                onToggleDevice: () =>
                                    _toggleDevice(context, controller, user),
                                onToggleStatus: () =>
                                    _toggleStatus(context, controller, user),
                                onDelete: () =>
                                    _deleteUser(context, controller, user),
                                isDeleting: isDeletingThisUser,
                              );
                            },
                          ),
              ),
            ],
          ),
          if (controller.isActionInProgress)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String filter, UsersController controller) {
    final isSelected = _filterStatus == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterStatus = filter);
        controller.filterUsers(filter == 'all' ? null : filter);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent.withOpacity(0.1),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 80, color: AppColors.textTertiary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'all'
                ? 'لا توجد نتائج مطابقة للبحث'
                : 'لا يوجد مستخدمين حالياً',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          if (_searchQuery.isNotEmpty || _filterStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterStatus = 'all';
                });
                final controller = context.read<UsersController>();
                controller.searchUsers('');
                controller.filterUsers(null);
              },
              child: const Text('مسح الفلتر'),
            ),
        ],
      ),
    );
  }

  void _showEditSubscriptionDialog(BuildContext context,
      UsersController controller, Map<String, dynamic> user) {
    final userId = user['id'].toString();
    final startDateController = TextEditingController(
        text: user['subscription_start'] != null
            ? user['subscription_start']
            : DateTime.now().toIso8601String().split('T')[0]);
    final endDateController = TextEditingController(
        text: user['subscription_end'] != null
            ? user['subscription_end']
            : DateTime.now()
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
                          initialDate: DateTime.parse(startDateController.text),
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
                        DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                        DropdownMenuItem(
                            value: 'quarterly', child: Text('ربع سنوي')),
                        DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
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
                  child: const Text('إلغاء')),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('تم تحديث الاشتراك بنجاح'),
                            backgroundColor: AppColors.success),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(controller.error ?? 'فشل تحديث الاشتراك'),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExtendDialog(BuildContext context, UsersController controller,
      Map<String, dynamic> user) {
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
                    onPressed: () async => await _extendSubscription(
                        context, controller, userId, 30),
                    child: const Text('+30 يوم'))),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async => await _extendSubscription(
                        context, controller, userId, 90),
                    child: const Text('+90 يوم'))),
            const SizedBox(height: 8),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async => await _extendSubscription(
                        context, controller, userId, 365),
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

  Future<void> _extendSubscription(BuildContext context,
      UsersController controller, String userId, int days) async {
    Navigator.pop(context);

    final success = await controller.extendSubscription(userId, days);

    if (context.mounted) {
      if (success) {
        await controller.refreshUserData(userId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تمديد الاشتراك $days يوماً'),
            backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(controller.error ?? 'فشل تمديد الاشتراك'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _toggleDevice(BuildContext context, UsersController controller,
      Map<String, dynamic> user) async {
    await controller.toggleMultiDevice(
        user['id'].toString(), user['multi_device_enabled'] ?? false);
  }

  Future<void> _toggleStatus(BuildContext context, UsersController controller,
      Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['is_active'] ? 'تعليق المستخدم' : 'تفعيل المستخدم'),
        content: Text(user['is_active']
            ? 'هل أنت متأكد من تعليق هذا المستخدم؟'
            : 'هل أنت متأكد من تفعيل هذا المستخدم؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.toggleUserStatus(
        user['id'].toString(), user['is_active'] ?? false);
  }

  Future<void> _deleteUser(BuildContext context, UsersController controller,
      Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${user['name']}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.deleteUser(user['id'].toString());
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

  Future<void> _showUserForm(BuildContext context, UsersController controller,
      {Map<String, dynamic>? user}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormPage(
          user: user,
          onSave: (userData) async {
            final success = user == null
                ? await controller.createUser(userData)
                : await controller.updateUser(user['id'].toString(), userData);

            if (!success) {
              throw Exception(controller.error ??
                  (user == null ? 'فشل إنشاء المستخدم' : 'فشل تحديث المستخدم'));
            }
            return true;
          },
        ),
      ),
    );

    if (result == true) {
      await controller.loadUsers(refresh: true);
      // ✅ تحديث أجهزة المستخدمين أيضاً
      final deviceController = context.read<DeviceManagementController>();
      await deviceController.loadAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.successMessage ??
                (user == null
                    ? 'تم إنشاء المستخدم بنجاح'
                    : 'تم تحديث المستخدم بنجاح')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        controller.clearMessages();
      }
    }
  }
}
