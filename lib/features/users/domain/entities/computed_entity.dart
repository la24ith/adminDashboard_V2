// domain/entities/computed_entity.dart
class ComputedEntity {
  final bool isActiveNow;
  final bool isExpired;
  final int daysRemaining;
  final int devicesUsed;
  final int devicesRemaining;

  const ComputedEntity({
    required this.isActiveNow,
    required this.isExpired,
    required this.daysRemaining,
    required this.devicesUsed,
    required this.devicesRemaining,
  });

  /// Factory method للقيم الافتراضية (مثلاً عند عدم وجود اشتراك)
  factory ComputedEntity.empty() {
    return const ComputedEntity(
      isActiveNow: false,
      isExpired: true,
      daysRemaining: 0,
      devicesUsed: 0,
      devicesRemaining: 0,
    );
  }

  /// للتحقق من صلاحية المستخدم للوصول إلى الميزات
  bool get hasValidSubscription =>
      isActiveNow && !isExpired && daysRemaining > 0;

  /// هل يمكن إضافة جهاز جديد؟
  bool get canAddDevice => devicesRemaining > 0;

  /// نسبة استخدام الأجهزة (لـ UI Progress indicators)
  double get devicesUsagePercentage {
    if (devicesUsed + devicesRemaining == 0) return 0.0;
    final total = devicesUsed + devicesRemaining;
    return devicesUsed / total;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComputedEntity &&
        other.isActiveNow == isActiveNow &&
        other.isExpired == isExpired &&
        other.daysRemaining == daysRemaining &&
        other.devicesUsed == devicesUsed &&
        other.devicesRemaining == devicesRemaining;
  }

  @override
  int get hashCode => Object.hash(
        isActiveNow,
        isExpired,
        daysRemaining,
        devicesUsed,
        devicesRemaining,
      );

  @override
  String toString() {
    return 'ComputedEntity(isActiveNow: $isActiveNow, isExpired: $isExpired, '
        'daysRemaining: $daysRemaining, devicesUsed: $devicesUsed, '
        'devicesRemaining: $devicesRemaining)';
  }
}
