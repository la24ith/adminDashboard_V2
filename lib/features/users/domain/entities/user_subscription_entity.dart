// domain/entities/user_subscription_entity.dart

import 'user_entity.dart';
import 'subscription_entity.dart';
import 'computed_entity.dart';
import 'devices_summary_entity.dart';
import 'device_entity.dart';

class UserSubscriptionEntity {
  final UserEntity user;
  final SubscriptionEntity subscription;
  final ComputedEntity computed;
  final DevicesSummaryEntity devicesSummary;
  final List<DeviceEntity> devices;

  const UserSubscriptionEntity({
    required this.user,
    required this.subscription,
    required this.computed,
    required this.devicesSummary,
    required this.devices,
  });

  factory UserSubscriptionEntity.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionEntity(
      user: UserEntity.fromJson(json['user'] ?? {}),
      subscription: SubscriptionEntity.fromJson(json['subscription'] ?? {}),
      computed: ComputedEntity.fromJson(json['computed'] ?? {}),
      devicesSummary:
          DevicesSummaryEntity.fromJson(json['devices_summary'] ?? {}),
      devices: (json['devices'] as List? ?? [])
          .map((device) => DeviceEntity.fromJson(device))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'subscription': subscription.toJson(),
      'computed': computed.toJson(),
      'devices_summary': devicesSummary.toJson(),
      'devices': devices.map((d) => d.toJson()).toList(),
    };
  }

  /// تحويل إلى Map للاستخدام في الـ UI
  Map<String, dynamic> toUiMap() {
    return {
      // بيانات المستخدم
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'role': user.role,
      'is_active': user.isActive,
      'patient_segment': user.patientSegment,

      // بيانات الاشتراك
      'subscription_id': subscription.id,
      'subscription_status': subscription.status,
      'plan_type': subscription.planType,
      'subscription_start':
          subscription.startDate.toIso8601String().split('T')[0],
      'subscription_end': subscription.endDate.toIso8601String().split('T')[0],
      'price': subscription.price,
      'max_devices': subscription.maxDevices,
      'is_multi_device': subscription.isMultiDevice,
      'multi_device_enabled': subscription.isMultiDevice,

      // البيانات المحسوبة
      'is_active_now': computed.isActiveNow,
      'is_expired': computed.isExpired,
      'days_remaining': computed.daysRemaining,
      'devices_used': computed.devicesUsed,
      'devices_remaining': computed.devicesRemaining,

      // ملخص الأجهزة
      'total_devices': devicesSummary.totalDevices,
      'approved_devices': devicesSummary.approvedDevices,
      'pending_devices': devicesSummary.pendingDevices,
      'blocked_devices': devicesSummary.blockedDevices,

      // الأجهزة
      'devices': devices.map((d) => d.toJson()).toList(),
      'devices_count': devices.length,

      // معلومات إضافية
      'created_by': subscription.createdBy,
      'subscription_notes': subscription.notes,
    };
  }

  @override
  String toString() =>
      'UserSubscriptionEntity(user: ${user.name}, subscription: ${subscription.id})';
}
