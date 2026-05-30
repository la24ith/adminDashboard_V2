class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final String token;
  final String tokenType;
  final AdminUser user;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // ✅ الـ API يرسل البيانات داخل مفتاح 'data'
    final data = json['data'];
    
    return LoginResponse(
      token: data['token'] ?? '',
      tokenType: 'Bearer',
      user: AdminUser.fromJson(data['user']),
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'admin',
      isActive: json['is_active'] ?? true,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
}

// ✅ للاستخدام العام (قد يعيد بيانات أكثر)
class UserData {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isActive;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'admin',
      isActive: json['is_active'] ?? true,
    );
  }
}