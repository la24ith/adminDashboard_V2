// domain/usecases/extend_subscription.dart

import 'package:dartz/dartz.dart';
import '../entities/subscription_entity.dart';
import '../repositories/user_repository.dart';

class ExtendSubscription {
  final UserRepository repository;

  const ExtendSubscription(this.repository);

  Future<Either<Failure, SubscriptionEntity>> call(
    int userId,
    int days,
  ) async {
    return await repository.extendSubscription(userId, days);
  }
}
