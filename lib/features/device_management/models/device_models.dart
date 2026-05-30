enum DeviceStatus { active, blocked }

class DeviceModel {
  final String id;
  final String name;
  final String ip;
  final DateTime lastLogin;
  final DeviceStatus status;

  DeviceModel({
    required this.id,
    required this.name,
    required this.ip,
    required this.lastLogin,
    required this.status,
  });

  bool get isActive => status == DeviceStatus.active;

  String get formattedLastLogin {
    return '${lastLogin.day}/${lastLogin.month}/${lastLogin.year} ${lastLogin.hour}:${lastLogin.minute.toString().padLeft(2, '0')}';
  }

  String get deviceIcon {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('iphone') || lowerName.contains('ios')) {
      return '📱';
    } else if (lowerName.contains('android')) {
      return '📱';
    } else if (lowerName.contains('web') || lowerName.contains('chrome')) {
      return '🌐';
    } else if (lowerName.contains('windows') || lowerName.contains('mac')) {
      return '💻';
    }
    return '📟';
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? ip,
    DateTime? lastLogin,
    DeviceStatus? status,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      lastLogin: lastLogin ?? this.lastLogin,
      status: status ?? this.status,
    );
  }
}

class UserDeviceModel {
  final String id;
  final String name;
  final String email;
  final List<DeviceModel> devices;

  UserDeviceModel({
    required this.id,
    required this.name,
    required this.email,
    required this.devices,
  });

  int get activeDevicesCount => devices.where((d) => d.isActive).length;
  int get blockedDevicesCount => devices.where((d) => !d.isActive).length;

  UserDeviceModel copyWith({
    String? id,
    String? name,
    String? email,
    List<DeviceModel>? devices,
  }) {
    return UserDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      devices: devices ?? this.devices,
    );
  }
}
