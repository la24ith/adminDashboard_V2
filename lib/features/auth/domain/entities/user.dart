class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? token;  // ✅ يمكن أن يكون null

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.token,
  });

  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
}