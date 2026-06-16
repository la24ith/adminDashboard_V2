// domain/usecases/update_subscription.dart

import 'package:dartz/dartz.dart';
import '../entities/subscription_entity.dart';
import '../repositories/user_repository.dart';

class UpdateSubscription {
  final UserRepository repository;

  const UpdateSubscription(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call(
    int userId,
    Map<String, dynamic> data,
  ) async {
    return await repository.updateSubscription(userId, data);
  }
}
