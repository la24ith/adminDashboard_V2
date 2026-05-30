import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:admin_dashboard/features/auth/domain/entities/user.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'admin_token';
  static const String _userKey = 'admin_user';

  // ==================== Token Management ====================
  
  static Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      print('⚠️ Warning: Attempted to save empty token');
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== User Management (موحد) ====================
  
  static Future<void> saveUser(User user) async {
    final userJson = jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'isActive': user.isActive,
    });
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<User?> getUser() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) return null;
      
      final Map<String, dynamic> data = jsonDecode(userJson);
      return User(
        id: data['id'],
        name: data['name'],
        email: data['email'],
        role: data['role'],
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('❌ Error parsing user data: $e');
      return null;
    }
  }

  static Future<String> getUserName() async {
    final user = await getUser();
    return user?.name ?? 'المدير';
  }

  static Future<String> getUserEmail() async {
    final user = await getUser();
    return user?.email ?? 'admin@example.com';
  }

  static Future<String> getUserRole() async {
    final user = await getUser();
    return user?.role ?? 'admin';
  }

  // ==================== Session Management ====================
  
  static Future<bool> isLoggedIn() async {
    final hasToken = await hasValidToken();
    final hasUser = await getUser() != null;
    return hasToken && hasUser;
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // ==================== Admin Data (للتوافق مع الكود القديم) ====================
  
  static Future<void> saveUserData({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    final user = User(
      id: id,
      name: name,
      email: email,
      role: role,
      isActive: true,
    );
    await saveUser(user);
  }

  static Future<String> getAdminName() async => getUserName();
  static Future<String> getAdminEmail() async => getUserEmail();
  static Future<String> getAdminRole() async => getUserRole();
  static Future<void> clearToken() async => clearSession();
}