import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final DateTime subscriptionStart;
  final DateTime subscriptionEnd;
  final bool isActive;
  final bool multiDeviceEnabled;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.subscriptionStart,
    required this.subscriptionEnd,
    required this.isActive,
    required this.multiDeviceEnabled,
  });

  bool get isSubscriptionActive =>
      subscriptionEnd.isAfter(DateTime.now()) && isActive;
  bool get isExpired => subscriptionEnd.isBefore(DateTime.now());
  int get daysRemaining => subscriptionEnd.difference(DateTime.now()).inDays;
  String get subscriptionStatus {
    if (!isActive) return 'suspended';
    if (isExpired) return 'expired';
    if (daysRemaining <= 7) return 'expiring';
    return 'active';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        subscriptionStart,
        subscriptionEnd,
        isActive,
        multiDeviceEnabled
      ];
}
