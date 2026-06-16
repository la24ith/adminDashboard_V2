// domain/entities/device_entity.dart

class DeviceEntity {
  final int id;
  final String deviceId;
  final String? deviceName;
  final String deviceType;
  final String? platform;
  final bool isApproved;
  final String status;
  final DateTime? lastActiveAt;

  const DeviceEntity({
    required this.id,
    required this.deviceId,
    this.deviceName,
    required this.deviceType,
    this.platform,
    required this.isApproved,
    required this.status,
    this.lastActiveAt,
  });

  factory DeviceEntity.fromJson(Map<String, dynamic> json) {
    return DeviceEntity(
      id: json['id'] ?? 0,
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'],
      deviceType: json['device_type'] ?? 'other',
      platform: json['platform'],
      isApproved: json['is_approved'] ?? false,
      status: json['status'] ?? 'inactive',
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'platform': platform,
      'is_approved': isApproved,
      'status': status,
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  @override
  String toString() =>
      'DeviceEntity(id: $id, deviceId: $deviceId, status: $status)';
}
