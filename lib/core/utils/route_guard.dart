import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class RouteGuard {
  static Future<bool> isAuthenticated() async {
    return await AuthService.isLoggedIn();
  }

  static Future<String?> redirectTo() async {
    final isLoggedIn = await isAuthenticated();
    if (!isLoggedIn) {
      return AppRoutes.adminLogin;
    }
    return null;
  }
}
