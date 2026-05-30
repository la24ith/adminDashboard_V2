import 'dart:io';

import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/reports_controller.dart';
import '../widgets/kpi_card.dart';
import '../widgets/achieved_goal_card.dart';
import '../widgets/expired_user_card.dart';

class UserReportsPage extends StatelessWidget {
  const UserReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ReportsController(),
      child: const _UserReportsPageContent(),
    );
  }
}

class _UserReportsPageContent extends StatefulWidget {
  const _UserReportsPageContent();

  @override
  State<_UserReportsPageContent> createState() =>
      _UserReportsPageContentState();
}

class _UserReportsPageContentState extends State<_UserReportsPageContent> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700; // ✅ تغيير threshold إلى 700

    // ✅ حساب ما إذا كانت البيانات قيد التحميل
    final isLoadingData = controller.isLoadingCommitments ||
        controller.isLoadingIdealWeights ||
        controller.isLoadingExpiredSubs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => controller.refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),

              _buildExportButtons(controller),
              const SizedBox(height: 24),

              // ✅ KPI Cards - معالجة Responsive بشكل أفضل
              if (!controller.isLoadingCommitments)
                _buildKPICards(controller, screenWidth)
              else
                _buildKPISkeleton(isSmallScreen),
              const SizedBox(height: 24),

              // ✅ Achieved Goal Section
              if (!controller.isLoadingIdealWeights)
                _buildAchievedGoalSection(controller)
              else
                _buildSectionSkeleton('المستخدمون الذين حققوا الوزن المثالي'),
              const SizedBox(height: 24),

              // ✅ Expired Users Section
              if (!controller.isLoadingExpiredSubs)
                _buildExpiredUsersSection(controller)
              else
                _buildSectionSkeleton('المستخدمون منتهية اشتراكاتهم'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تقارير المستخدمين',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'إحصائيات وتحليلات عن أداء المستخدمين والتزامهم',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildExportButtons(ReportsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.isExportingPDF
                  ? null
                  : () => _handleExport(context, controller, 'pdf'),
              icon: controller.isExportingPDF
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                controller.isExportingPDF ? 'جاري التصدير...' : 'PDF',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.isExportingExcel
                  ? null
                  : () => _handleExport(context, controller, 'excel'),
              icon: controller.isExportingExcel
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.table_chart),
              label: Text(
                controller.isExportingExcel ? 'جاري التصدير...' : 'Excel',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ بناء KPI Cards - مع معالجة أفضل للـ Overflow
  Widget _buildKPICards(ReportsController controller, double screenWidth) {
    final isExtraSmall = screenWidth < 500;
    
    if (isExtraSmall) {
      // ✅ شاشات صغيرة جداً - عرض عمودي
      return Column(
        children: [
          KPICard(
            title: 'إجمالي المستخدمين',
            value: controller.totalUsers.toString(),
            icon: Icons.people_outline,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          KPICard(
            title: 'معدل الالتزام',
            value: '${controller.avgCommitment.toStringAsFixed(0)}%',
            icon: Icons.check_circle_outline,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          KPICard(
            title: 'حققوا الهدف',
            value: controller.achievedGoal.toString(),
            icon: Icons.emoji_events_outlined,
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          KPICard(
            title: 'اشتراكات منتهية',
            value: controller.expiredSubscriptions.toString(),
            icon: Icons.cancel_outlined,
            color: AppColors.error,
          ),
        ],
      );
    }
    
    // ✅ شاشات متوسطة وكبيرة - عرض شبكي
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: screenWidth < 900 ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        KPICard(
          title: 'إجمالي المستخدمين',
          value: controller.totalUsers.toString(),
          icon: Icons.people_outline,
          color: AppColors.primary,
        ),
        KPICard(
          title: 'معدل الالتزام',
          value: '${controller.avgCommitment.toStringAsFixed(0)}%',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
        KPICard(
          title: 'حققوا الهدف',
          value: controller.achievedGoal.toString(),
          icon: Icons.emoji_events_outlined,
          color: AppColors.warning,
        ),
        KPICard(
          title: 'اشتراكات منتهية',
          value: controller.expiredSubscriptions.toString(),
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildKPISkeleton(bool isSmallScreen) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }

 Widget _buildSectionSkeleton(String title) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ استخدام Row مع Expanded لمنع الـ Overflow
        Row(
          children: [
            // الـ CircularProgressIndicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            // ✅ استخدام Expanded للنص الطويل
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,  // ✅ قص النص الزائد
                maxLines: 2,                      // ✅ حد أقصى سطرين
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
// ✅ قسم المستخدمين الذين حققوا الوزن المثالي
Widget _buildAchievedGoalSection(ReportsController controller) {
  final users = controller.idealWeightsData['users'] ?? [];
  
  if (users.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'لا يوجد مستخدمون حققوا الوزن المثالي حالياً',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ استخدام Expanded للنص الطويل
        Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🏆 المستخدمون الذين حققوا الوزن المثالي',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length > 5 ? 5 : users.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AchievedGoalCard(user: users[index]),
            );
          },
        ),
        if (users.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+ ${users.length - 5} مستخدمين آخرين',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
      ],
    ),
  );
}

// ✅ قسم المستخدمين منتهية اشتراكاتهم
Widget _buildExpiredUsersSection(ReportsController controller) {
  final users = controller.expiredSubsData['users'] ?? [];
  
  if (users.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'لا يوجد مستخدمين منتهية اشتراكاتهم حالياً',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ استخدام Expanded للنص الطويل
        Row(
          children: [
            const Icon(Icons.warning_amber, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⏰ المستخدمون منتهية اشتراكاتهم',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length > 5 ? 5 : users.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpiredUserCard(user: users[index]),
            );
          },
        ),
        if (users.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+ ${users.length - 5} مستخدمين آخرين',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
      ],
    ),
  );
}
  Future<void> _handleExport(
    BuildContext context,
    ReportsController controller,
    String type,
  ) async {
    _showProgress(context, type);

    String? path;

    if (type == 'pdf') {
      path = await controller.exportPDF();
    } else if (type == 'excel') {
      path = await controller.exportExcel();
    }

    if (!context.mounted) return;

    Navigator.of(context).pop();

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تصدير ${type.toUpperCase()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showSuccessDialog(context, controller, path, type);
  }

  void _showProgress(BuildContext context, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text('جاري تجهيز ملف ${type.toUpperCase()}...'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    ReportsController controller,
    String path,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('تم تصدير ${type.toUpperCase()}'),
          content: const Text('تم إنشاء الملف بنجاح.'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: path),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ المسار'),
                  ),
                );
              },
              child: const Text('نسخ المسار'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final file = File(path);
                final bytes = await file.readAsBytes();
                final fileName = 'users_report_${DateTime.now().millisecondsSinceEpoch}';

                await controller.openExportedFile(
                  fileName: fileName,
                  fileBytes: bytes,
                  fileExtension: type,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('فتح'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }
}