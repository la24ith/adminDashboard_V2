import 'package:admin_dashboard/core/widgets/animated_widgets.dart';
import 'package:admin_dashboard/features/device_management/pages/user_devices_screen.dart';
import 'package:admin_dashboard/features/users/presentation/controllers/users_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';

class UserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onExtend;
  final VoidCallback onEditSubscription;
  final VoidCallback onToggleDevice;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final bool isDeleting;
  final VoidCallback? onRefresh;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onExtend,
    required this.onEditSubscription,
    required this.onToggleDevice,
    required this.onToggleStatus,
    required this.onDelete,
    this.isDeleting = false,
    this.onRefresh,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _isHovered = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || _isDisposed) return const SizedBox.shrink();

    final daysRemaining = widget.user['days_remaining'] ?? 0;
    final isExpired = widget.user['is_expired'] ?? false;
    final devicesUsed = widget.user['devices_used'] ?? 0;
    final maxDevices = widget.user['max_devices'] ?? 1;
    final devicesRemaining =
        widget.user['devices_remaining'] ?? (maxDevices - devicesUsed);
    final controller = context.watch<UsersController>();
    final isDeletingThisUser = controller.isDeleting &&
        controller.deletingUserId == widget.user['id'].toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isActive = widget.user['is_active'] ?? true;

    final subscriptionStart =
        widget.user['subscription_start'] ?? widget.user['start_date'] ?? '—';
    final subscriptionEnd =
        widget.user['subscription_end'] ?? widget.user['end_date'] ?? '—';
    final hasMultiDevice = widget.user['multi_device_enabled'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDevicesScreen(
              userId: widget.user['id'],
              userName: widget.user['name'],
              userEmail: widget.user['email'],
            ),
          ),
        );
      },
      child: ScaleOnHover(
        scale: 1.02,
        child: MouseRegion(
          onEnter: (_) {
            if (mounted && !_isDisposed) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) {
            if (mounted && !_isDisposed) {
              setState(() => _isHovered = false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: _isHovered
                ? Matrix4.translationValues(0, -4, 0)
                : Matrix4.identity(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.12 : 0.06),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: Offset(0, _isHovered ? 6 : 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: isDeletingThisUser ? 0.5 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final showCompact = constraints.maxWidth < 500;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // First row: Avatar, User Info, Menu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          isActive
                                              ? AppColors.success
                                              : AppColors.warning,
                                          isActive
                                              ? AppColors.accent
                                              : AppColors.error
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.user['name']?.isNotEmpty == true
                                            ? widget.user['name'][0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // User Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.user['name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.user['email'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Menu Button
                                  if ((_isHovered || isMobile) &&
                                      !isDeletingThisUser)
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: AppColors.textTertiary),
                                      onSelected: (value) => _handleMenuAction(
                                          value, isDeletingThisUser),
                                      offset: const Offset(0, 40),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 4,
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 18,
                                                  color: AppColors.info),
                                              SizedBox(width: 12),
                                              Text('تعديل المستخدم')
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'extend',
                                          child: Row(
                                            children: [
                                              Icon(Icons.timer_outlined,
                                                  size: 18,
                                                  color: AppColors.warning),
                                              SizedBox(width: 12),
                                              Text('تمديد الاشتراك')
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit_subscription',
                                          child: Row(
                                            children: [
                                              Icon(Icons.subscriptions,
                                                  size: 18,
                                                  color: AppColors.info),
                                              SizedBox(width: 12),
                                              Text('تعديل الاشتراك')
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'toggle_device',
                                          child: Row(
                                            children: [
                                              Icon(Icons.devices_outlined,
                                                  size: 18,
                                                  color: AppColors.accent),
                                              SizedBox(width: 12),
                                              Text('تبديل وضع الأجهزة')
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'toggle_status',
                                          child: Row(
                                            children: [
                                              Icon(
                                                  isActive
                                                      ? Icons.block_outlined
                                                      : Icons
                                                          .check_circle_outline,
                                                  size: 18,
                                                  color: isActive
                                                      ? AppColors.warning
                                                      : AppColors.success),
                                              const SizedBox(width: 12),
                                              Text(isActive
                                                  ? 'تعليق المستخدم'
                                                  : 'تفعيل المستخدم'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 18,
                                                  color: AppColors.error),
                                              SizedBox(width: 12),
                                              Text('حذف المستخدم',
                                                  style: TextStyle(
                                                      color: AppColors.error))
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (isDeletingThisUser)
                                    const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Second row: Devices info (compact or normal)
                              if (showCompact)
                                Column(
                                  children: [
                                    _buildCompactInfoItem(
                                      icon: Icons.devices,
                                      label: 'الأجهزة المستخدمة',
                                      value: '$devicesUsed / $maxDevices',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactInfoItem(
                                      icon: Icons.devices_other,
                                      label: 'الأجهزة المتبقية',
                                      value: '$devicesRemaining',
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.devices,
                                        label: 'الأجهزة المستخدمة',
                                        value: '$devicesUsed / $maxDevices',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.devices_other,
                                        label: 'الأجهزة المتبقية',
                                        value: '$devicesRemaining',
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        }),
                      ),

                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Info Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final isSmallScreen = constraints.maxWidth < 400;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSmallScreen) ...[
                                _buildCompactInfoItem(
                                  icon: Icons.calendar_today,
                                  label: 'تاريخ البداية',
                                  value: _formatDate(subscriptionStart),
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInfoItem(
                                  icon: Icons.event_busy,
                                  label: 'تاريخ النهاية',
                                  value: _formatDate(subscriptionEnd),
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInfoItem(
                                  icon: Icons.devices,
                                  label: 'وضع الأجهزة',
                                  value: hasMultiDevice ? 'متعدد' : 'جهاز واحد',
                                ),
                                const SizedBox(height: 8),
                                _buildCompactInfoItem(
                                  icon: Icons.smartphone,
                                  label: 'عدد الأجهزة',
                                  value:
                                      '${widget.user['devices_count'] ?? 0} أجهزة',
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.calendar_today,
                                        label: 'تاريخ البداية',
                                        value: _formatDate(subscriptionStart),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.event_busy,
                                        label: 'تاريخ النهاية',
                                        value: _formatDate(subscriptionEnd),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.devices,
                                        label: 'وضع الأجهزة',
                                        value: hasMultiDevice
                                            ? 'متعدد'
                                            : 'جهاز واحد',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInfoItem(
                                        icon: Icons.smartphone,
                                        label: 'عدد الأجهزة',
                                        value:
                                            '${widget.user['devices_count'] ?? 0} أجهزة',
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 12),

                              // Status Badges
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStatusBadge(
                                      isExpired, daysRemaining, isActive),
                                  if (hasMultiDevice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: AppColors.infoLight,
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: const Text(
                                        'أجهزة متعددة',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.info),
                                      ),
                                    ),
                                ],
                              ),

                              // Progress Indicator for expiring soon
                              if (!isExpired &&
                                  daysRemaining > 0 &&
                                  daysRemaining <= 30)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('المتبقي من الاشتراك',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color:
                                                      AppColors.textTertiary)),
                                          Text(
                                            '$daysRemaining يوماً',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.warning),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: daysRemaining / 30,
                                          backgroundColor:
                                              AppColors.surfaceVariant,
                                          color: daysRemaining <= 7
                                              ? AppColors.error
                                              : AppColors.warning,
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Central progress layer while deleting
                if (isDeletingThisUser)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
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

  Widget _buildInfoItem(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactInfoItem(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isExpired, int daysRemaining, bool isActive) {
    String text;
    Color color;
    Color bgColor;

    if (!isActive) {
      text = 'موقوف';
      color = AppColors.warning;
      bgColor = AppColors.warningLight;
    } else if (isExpired) {
      text = 'منتهي';
      color = AppColors.error;
      bgColor = AppColors.errorLight;
    } else if (daysRemaining <= 7) {
      text = 'ينتهي قريباً';
      color = AppColors.warning;
      bgColor = AppColors.warningLight;
    } else {
      text = 'نشط';
      color = AppColors.success;
      bgColor = AppColors.successLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _handleMenuAction(String value, bool isDeletingThisUser) {
    if (isDeletingThisUser) return;
    if (!mounted || _isDisposed) return;

    switch (value) {
      case 'edit':
        widget.onEdit();
        break;
      case 'extend':
        widget.onExtend();
        break;
      case 'edit_subscription':
        widget.onEditSubscription();
        break;
      case 'toggle_device':
        widget.onToggleDevice();
        break;
      case 'toggle_status':
        widget.onToggleStatus();
        break;
      case 'delete':
        widget.onDelete();
        break;
    }
  }
}
