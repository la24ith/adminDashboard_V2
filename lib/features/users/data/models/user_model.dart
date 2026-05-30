import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.subscriptionStart,
    required super.subscriptionEnd,
    required super.isActive,
    required super.multiDeviceEnabled,
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      subscriptionStart: user.subscriptionStart,
      subscriptionEnd: user.subscriptionEnd,
      isActive: user.isActive,
      multiDeviceEnabled: user.multiDeviceEnabled,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      subscriptionStart: DateTime.parse(json['subscriptionStart']),
      subscriptionEnd: DateTime.parse(json['subscriptionEnd']),
      isActive: json['isActive'],
      multiDeviceEnabled: json['multiDeviceEnabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subscriptionStart': subscriptionStart.toIso8601String(),
      'subscriptionEnd': subscriptionEnd.toIso8601String(),
      'isActive': isActive,
      'multiDeviceEnabled': multiDeviceEnabled,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      subscriptionStart: subscriptionStart,
      subscriptionEnd: subscriptionEnd,
      isActive: isActive,
      multiDeviceEnabled: multiDeviceEnabled,
    );
  }
}
