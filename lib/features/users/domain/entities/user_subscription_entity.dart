// domain/entities/user_subscription_entity.dart
import 'package:admin_dashboard/features/auth/domain/entities/user.dart';
import 'package:admin_dashboard/features/users/domain/entities/computed_entity.dart';
import 'package:admin_dashboard/features/users/domain/entities/devices_summary_entity.dart';

class UserSubscriptionEntity {
  final User user;
  final SubscriptionEntity? subscription;
  final ComputedEntity? computed;
  final DevicesSummaryEntity? devicesSummary;

  UserSubscriptionEntity({
    required this.user,
    this.subscription,
    this.computed,
    this.devicesSummary,
  });
}

class SubscriptionEntity {
  final int id;
  final String status;
  final String planType;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int maxDevices;
  final bool isMultiDevice;

  SubscriptionEntity({
    required this.id,
    required this.status,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.maxDevices,
    required this.isMultiDevice,
  });
}

// ComputedEntity, DevicesSummaryEntity مشابهة للمودلز
