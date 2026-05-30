import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/dashboard_controller.dart';

class DashboardSidebar extends StatelessWidget {
  final DashboardController controller;
  final VoidCallback? onItemTap;

  const DashboardSidebar({
    super.key,
    required this.controller,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: controller.isSidebarCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 24),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: 'لوحة التحكم',
                  page: AdminPage.dashboard,
                ),
                _buildMenuItem(
                  icon: Icons.people_outlined,
                  title: 'المستخدمين',
                  page: AdminPage.users,
                ),
                _buildMenuItem(
                  icon: Icons.article_outlined,
                  title: 'المنشورات',
                  page: AdminPage.posts,
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'الإشعارات',
                  page: AdminPage.notifications,
                ),
                _buildMenuItem(
                  icon: Icons.ads_click_outlined,
                  title: 'الإعلانات',
                  page: AdminPage.ads,
                ),
                _buildMenuItem(
                  icon: Icons.report,
                  title: 'تقارير المستخدمين ',
                  page: AdminPage.reports,
                ),
                _buildMenuItem(
                  icon: Icons.devices,
                  title: 'ادارةالاجهزة',
                  page: AdminPage.devices,
                ),
              ],
            ),
          ),

          // Collapse Button (Desktop only)
          if (!controller.isMobileLayout) _buildCollapseButton(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.fitness_center, color: Colors.white, size: 24),
          ),
          if (!controller.isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'WeightCare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required AdminPage page,
  }) {
    final isSelected = controller.currentPage == page;

    return InkWell(
      onTap: () {
        controller.navigateToPage(page);
        // Close drawer on mobile after tapping
        if (controller.isMobileLayout && onItemTap != null) {
          onItemTap!();
        }
      },
      hoverColor: Colors.white.withOpacity(0.1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: isSelected ? Colors.white : Colors.white70),
            if (!controller.isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollapseButton() {
    return InkWell(
      onTap: controller.toggleSidebar,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              controller.isSidebarCollapsed
                  ? Icons.chevron_right
                  : Icons.chevron_left,
              size: 20,
              color: Colors.white70,
            ),
            if (!controller.isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              const Text(
                'إخفاء القائمة',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
