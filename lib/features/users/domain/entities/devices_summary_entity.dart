// domain/entities/devices_summary_entity.dart

class DevicesSummaryEntity {
  final int totalDevices;
  final int approvedDevices;
  final int pendingDevices;
  final int blockedDevices;

  const DevicesSummaryEntity({
    required this.totalDevices,
    required this.approvedDevices,
    required this.pendingDevices,
    required this.blockedDevices,
  });

  factory DevicesSummaryEntity.fromJson(Map<String, dynamic> json) {
    return DevicesSummaryEntity(
      totalDevices: json['total_devices'] ?? 0,
      approvedDevices: json['approved_devices'] ?? 0,
      pendingDevices: json['pending_devices'] ?? 0,
      blockedDevices: json['blocked_devices'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'approved_devices': approvedDevices,
      'pending_devices': pendingDevices,
      'blocked_devices': blockedDevices,
    };
  }

  factory DevicesSummaryEntity.empty() {
    return const DevicesSummaryEntity(
      totalDevices: 0,
      approvedDevices: 0,
      pendingDevices: 0,
      blockedDevices: 0,
    );
  }

  double get approvalPercentage {
    if (totalDevices == 0) return 0.0;
    return approvedDevices / totalDevices;
  }

  double get pendingPercentage {
    if (totalDevices == 0) return 0.0;
    return pendingDevices / totalDevices;
  }

  double get blockedPercentage {
    if (totalDevices == 0) return 0.0;
    return blockedDevices / totalDevices;
  }

  bool get hasPendingDevices => pendingDevices > 0;
  bool get hasExceededLimit => totalDevices > approvedDevices + pendingDevices;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DevicesSummaryEntity &&
        other.totalDevices == totalDevices &&
        other.approvedDevices == approvedDevices &&
        other.pendingDevices == pendingDevices &&
        other.blockedDevices == blockedDevices;
  }

  @override
  int get hashCode => Object.hash(
        totalDevices,
        approvedDevices,
        pendingDevices,
        blockedDevices,
      );

  @override
  String toString() {
    return 'DevicesSummaryEntity(totalDevices: $totalDevices, '
        'approvedDevices: $approvedDevices, pendingDevices: $pendingDevices, '
        'blockedDevices: $blockedDevices)';
  }
}
