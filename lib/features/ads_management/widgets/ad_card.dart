import 'package:admin_dashboard/features/ads_management/models/ad_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

class AdCard extends StatefulWidget {
  final AdModel ad; // تغيير من Map إلى AdModel
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const AdCard({
    super.key,
    required this.ad, // تغيير النوع
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isActive = widget.ad.isActive ?? false;
    final isExpired = _isExpired();
    final hasImage = widget.ad.image != null && widget.ad.image!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: widget.ad.image!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.grey.shade200,
                            child: const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 160,
                            color: Colors.grey.shade300,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text(
                                  'فشل تحميل الصورة',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          width: double.infinity,
                          color: AppColors.accent.withOpacity(0.1),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.text_fields,
                                    size: 40,
                                    color: AppColors.accent.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                Text(widget.ad.title ?? 'إعلان نصي',
                                    style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                ),
                // Gradient overlay for better text visibility
                if (hasImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4)
                            ]),
                      ),
                    ),
                  ),
                // Status and stats overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${widget.ad ?? 0} نقرة',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.ad.title ?? 'بدون عنوان',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Content if available
                  if (widget.ad.content != null &&
                      widget.ad.content!.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.ad.content ?? 'بدون محتوى',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Type and Position
                  Row(
                    children: [
                      Icon(Icons.category,
                          size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${widget.ad.type ?? 'banner'} • ${widget.ad.position ?? 'top'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Target Audience
                  if (widget.ad.targetAudience != null &&
                      (widget.ad.targetAudience as List).isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (widget.ad.targetAudience as List)
                                .take(2)
                                .map((e) => _getAudienceLabel(e))
                                .join(', '),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Dates
                  Row(
                    children: [
                      _buildDateItem(
                          Icons.calendar_today, widget.ad.startDate.toString()),
                      const SizedBox(width: 12),
                      _buildDateItem(
                          Icons.event_busy, widget.ad.endDate.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle Switch with status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: isActive && !isExpired,
                              onChanged: isExpired
                                  ? null
                                  : (value) => widget.onToggle(),
                              activeColor: AppColors.success,
                              inactiveThumbColor: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                      // Action Buttons
                      if (_isHovered || isMobile)
                        Row(
                          children: [
                            IconButton(
                              onPressed: widget.onEdit,
                              icon: Icon(Icons.edit_outlined,
                                  size: 18, color: AppColors.info),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(),
                              icon: Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isExpired = _isExpired();
    final isActive = widget.ad.isActive ?? false;

    String text;
    Color color;
    Color bgColor;

    if (isExpired) {
      text = 'منتهي';
      color = AppColors.error;
      bgColor = AppColors.errorLight;
    } else if (isActive) {
      text = 'نشط';
      color = AppColors.success;
      bgColor = AppColors.successLight;
    } else {
      text = 'غير نشط';
      color = AppColors.warning;
      bgColor = AppColors.warningLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildDateItem(IconData icon, String? dateString) {
    if (dateString == null) return const SizedBox.shrink();
    try {
      final date = DateTime.parse(dateString);
      return Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text('${date.day}/${date.month}/${date.year}',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _getStatusText() {
    final isExpired = _isExpired();
    final isActive = widget.ad.isActive ?? false;
    if (isExpired) return 'منتهي';
    if (isActive) return 'نشط';
    return 'غير نشط';
  }

  Color _getStatusColor() {
    final isExpired = _isExpired();
    final isActive = widget.ad.isActive ?? false;
    if (isExpired) return AppColors.error;
    if (isActive) return AppColors.success;
    return AppColors.warning;
  }

  String _getAudienceLabel(String key) {
    switch (key) {
      case 'general':
        return 'عام';
      case 'diabetes':
        return 'مرضى السكري';
      case 'cubs':
        return 'الأشبال';
      case 'hypertension':
        return 'ارتفاع الضغط';
      case 'pregnancy':
        return 'الحوامل';
      default:
        return key;
    }
  }

  bool _isExpired() {
    if (widget.ad.endDate == null) return false;
    try {
      final endDate = DateTime.parse(widget.ad.endDate.toString());
      return endDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
