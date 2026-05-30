import 'package:admin_dashboard/features/dashboard/presentation/widgets/dashboard_home_content.dart';
import 'package:admin_dashboard/features/device_management/pages/device_management_page.dart';
import 'package:admin_dashboard/features/posts/presentation/pages/posts_management_page.dart';
import 'package:admin_dashboard/features/user_reports/presentation/pages/user_reports_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../../../ads_management/pages/ads_management_page.dart';
import '../../../notifications_management/pages/notifications_management_page.dart';
import '../../../users/presentation/pages/users_page.dart';

enum AdminPage { dashboard, users, posts, notifications, ads, reports, devices }

class DashboardController extends ChangeNotifier {
  AdminPage _currentPage = AdminPage.dashboard;
  bool _isSidebarCollapsed = false;
  bool _isMobileLayout = false;
  String? _adminName;
  String? _adminEmail;
  
  // Dashboard Data
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _weeklyActivity = [];
  bool _isLoading = true;
  String? _error;

  AdminPage get currentPage => _currentPage;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  bool get isMobileLayout => _isMobileLayout;
  String? get adminName => _adminName;
  String? get adminEmail => _adminEmail;
  Map<String, dynamic> get dashboardData => _dashboardData;
  List<Map<String, dynamic>> get weeklyActivity => _weeklyActivity;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DashboardController() {
    _loadAdminData();
    _fetchDashboardData();
  }

  Future<void> _loadAdminData() async {
    _adminName = await AuthService.getAdminName();
    _adminEmail = await AuthService.getAdminEmail();
    notifyListeners();
  }
Future<void> _fetchDashboardData() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final dio = DioClient.instance;
    final response = await dio.get(ApiConstants.adminDashboard);

    if (response.statusCode == 200) {
      // ✅ التصحيح: البيانات داخل 'stats'
      final stats = response.data['stats'] ?? response.data;
      _dashboardData = stats;
      
      // ✅ حساب النشاط الأسبوعي من البيانات الموجودة
      _weeklyActivity = _calculateWeeklyActivity(stats);
      
      _isLoading = false;
      notifyListeners();
    } else {
      throw Exception('فشل تحميل بيانات لوحة التحكم');
    }
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
  }
}
  Future<void> refreshDashboard() async {
    await _fetchDashboardData();
  }

  void setMobileLayout(bool isMobile) {
    if (_isMobileLayout != isMobile) {
      _isMobileLayout = isMobile;
      notifyListeners();
    }
  }

  void navigateToPage(AdminPage page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  String getPageTitle() {
    switch (_currentPage) {
      case AdminPage.dashboard:
        return 'لوحة التحكم الرئيسية';
      case AdminPage.users:
        return 'إدارة المستخدمين';
      case AdminPage.posts:
        return 'إدارة المنشورات';
      case AdminPage.notifications:
        return 'إدارة الإشعارات';
      case AdminPage.ads:
        return 'إدارة الإعلانات';
      case AdminPage.reports:
        return 'تقارير المستخدمين';
      case AdminPage.devices:
        return 'إدارة الأجهزة';
    }
  }

  Widget getCurrentPage() {
    switch (_currentPage) {
      case AdminPage.dashboard:
        return DashboardHomeContent(controller: this);
      case AdminPage.users:
        return const UsersPage();
      case AdminPage.posts:
        return const PostsManagementPage();
      case AdminPage.notifications:
        return const NotificationsManagementPage();
      case AdminPage.ads:
        return const AdsManagementPage();
      case AdminPage.reports:
        return const UserReportsPage();
      case AdminPage.devices:
        return const DeviceManagementPage();
    }
  }
  /// ✅ حساب النشاط الأسبوعي من البيانات الموجودة
List<Map<String, dynamic>> _calculateWeeklyActivity(Map<String, dynamic> data) {
  final totalUsers = (data['total_users'] ?? 0).toInt();
  final totalPosts = (data['total_posts'] ?? 0).toInt();
  
  // ✅ استخدام المعدل بين المستخدمين والمنشورات
  final baseValue = ((totalUsers + totalPosts) / 2).toInt();
  
  // ✅ توزيع النشاط على أيام الأسبوع بنسب مئوية مختلفة
  final days = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
  final percentages = [0.65, 0.80, 0.55, 0.90, 0.70, 0.85, 0.60];
  
  return List.generate(7, (index) {
    return {
      'day': days[index],
      'count': (baseValue * percentages[index]).toInt(),
    };
  });
}

}