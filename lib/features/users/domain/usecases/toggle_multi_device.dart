// domain/usecases/toggle_multi_device.dart

import 'package:dartz/dartz.dart';
import '../entities/subscription_entity.dart';
import '../repositories/user_repository.dart';

class ToggleMultiDevice {
  final UserRepository repository;

  const ToggleMultiDevice(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call(
    int userId,
    bool currentStatus,
  ) async {
    return await repository.toggleMultiDevice(userId, currentStatus);
  }
}
