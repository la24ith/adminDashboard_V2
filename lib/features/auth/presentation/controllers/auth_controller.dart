import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
  }) {
    _loadSavedSession();
  }

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ✅ تحميل الجلسة المحفوظة عند بدء التطبيق
  Future<void> _loadSavedSession() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      _currentUser = await AuthService.getUser();
      notifyListeners();
      print('✅ Session loaded for: ${_currentUser?.name}');
    }
  }

  /// ✅ تسجيل الدخول
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('📍 AuthController: Starting login for $email');

    final result = await loginUseCase(email, password);

    return result.fold(
      (failure) {
        print('❌ AuthController: Login failed - ${failure.message}');
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (user) async {
        print('✅ AuthController: Login successful - ${user.name}');
        _currentUser = user;

        await AuthService.saveToken(user.token!);
        await AuthService.saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  /// ✅ تسجيل الخروج
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    print('📍 AuthController: Logging out');

    final result = await logoutUseCase();

    result.fold(
      (failure) {
        print('❌ AuthController: Logout error - ${failure.message}');
        _error = failure.message;
      },
      (_) {
        print('✅ AuthController: Logout successful');
        _currentUser = null;
      },
    );

    await AuthService.clearSession();
    _isLoading = false;
    notifyListeners();
  }

  /// ✅ التحقق من وجود جلسة نشطة
  Future<bool> checkSession() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn) {
      final user = await AuthService.getUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        print('✅ AuthController: Session restored for ${user.name}');
        return true;
      }
    }

    print('❌ AuthController: No active session');
    return false;
  }

  /// ✅ اسم المستخدم (متزامن - من الذاكرة)
  String getCurrentUserName() {
    return _currentUser?.name ?? 'المدير';
  }

  /// ✅ بريد المستخدم (متزامن - من الذاكرة)
  String getCurrentUserEmail() {
    return _currentUser?.email ?? 'admin@example.com';
  }

  /// ✅ دور المستخدم (متزامن - من الذاكرة)
  String getCurrentUserRole() {
    return _currentUser?.role ?? 'admin';
  }

  /// ✅ اسم المستخدم (غير متزامن - من التخزين)
  Future<String> getUserNameFromStorage() async {
    return await AuthService.getUserName();
  }

  /// ✅ بريد المستخدم (غير متزامن - من التخزين)
  Future<String> getUserEmailFromStorage() async {
    return await AuthService.getUserEmail();
  }

  /// ✅ دور المستخدم (غير متزامن - من التخزين)
  Future<String> getUserRoleFromStorage() async {
    return await AuthService.getUserRole();
  }

  /// ✅ التحقق من أن المستخدم هو أدمن
  bool get isAdmin {
    return _currentUser?.role == 'admin';
  }

  /// ✅ التحقق من أن المستخدم هو مشرف
  bool get isSupervisor {
    return _currentUser?.role == 'supervisor';
  }

  /// ✅ مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
