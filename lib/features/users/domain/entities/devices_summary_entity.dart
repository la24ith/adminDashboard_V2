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

  /// Factory method للقيم الافتراضية
  factory DevicesSummaryEntity.empty() {
    return const DevicesSummaryEntity(
      totalDevices: 0,
      approvedDevices: 0,
      pendingDevices: 0,
      blockedDevices: 0,
    );
  }

  /// نسبة الأجهزة الموافقة
  double get approvalPercentage {
    if (totalDevices == 0) return 0.0;
    return approvedDevices / totalDevices;
  }

  /// نسبة الأجهزة المعلقة
  double get pendingPercentage {
    if (totalDevices == 0) return 0.0;
    return pendingDevices / totalDevices;
  }

  /// نسبة الأجهزة المحظورة
  double get blockedPercentage {
    if (totalDevices == 0) return 0.0;
    return blockedDevices / totalDevices;
  }

  /// هل يوجد أجهزة معلقة تحتاج إلى مراجعة؟
  bool get hasPendingDevices => pendingDevices > 0;

  /// هل تجاوز المستخدم الحد المسموح؟
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
