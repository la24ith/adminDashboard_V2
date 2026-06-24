// domain/usecases/get_user_weight_history.dart

import 'package:dartz/dartz.dart';
import '../entities/weight_entity.dart';
import '../repositories/user_repository.dart';

class GetUserWeightHistory {
  final UserRepository repository;

  const GetUserWeightHistory(this.repository);

  Future<Either<Failure, List<WeightEntity>>> call(
    int userId, {
    int limit = 10,
  }) async {
    return await repository.getUserWeightHistory(userId, limit: limit);
  }
}
