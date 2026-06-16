// domain/entities/subscription_entity.dart

class SubscriptionEntity {
  final int id;
  final String status;
  final String planType;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final int maxDevices;
  final bool isMultiDevice;
  final String? notes;
  final int? createdBy;

  const SubscriptionEntity({
    required this.id,
    required this.status,
    required this.planType,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.maxDevices,
    required this.isMultiDevice,
    this.notes,
    this.createdBy,
  });

  factory SubscriptionEntity.fromJson(Map<String, dynamic> json) {
    return SubscriptionEntity(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'inactive',
      planType: json['plan_type'] ?? 'monthly',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      maxDevices: json['max_devices'] ?? 1,
      isMultiDevice: json['is_multi_device'] ?? false,
      notes: json['notes'],
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'plan_type': planType,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'price': price.toString(),
      'max_devices': maxDevices,
      'is_multi_device': isMultiDevice,
      'notes': notes,
      'created_by': createdBy,
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired' || endDate.isBefore(DateTime.now());
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  @override
  String toString() =>
      'SubscriptionEntity(id: $id, status: $status, endDate: $endDate)';
}
