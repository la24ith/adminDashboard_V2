import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_topbar.dart';

class AdminDashboard extends StatefulWidget {
  final AdminPage? initialPage;

  const AdminDashboard({super.key, this.initialPage});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late DashboardController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    if (widget.initialPage != null) {
      _controller.navigateToPage(widget.initialPage!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScreenSize();
    });
  }

  void _checkScreenSize() {
    final width = MediaQuery.of(context).size.width;
    _controller.setMobileLayout(width < 800);
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          drawer: _controller.isMobileLayout
              ? Drawer(
                  child: DashboardSidebar(
                    controller: _controller,
                    onItemTap: _closeDrawer,
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!_controller.isMobileLayout)
                DashboardSidebar(controller: _controller),
              Expanded(
                child: Column(
                  children: [
                    DashboardTopbar(
                      controller: _controller,
                      onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(
                      child: _controller.getCurrentPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
