// domain/usecases/add_weight.dart

import 'package:dartz/dartz.dart';
import '../entities/weight_entity.dart';
import '../repositories/user_repository.dart';

class AddWeight {
  final UserRepository repository;

  const AddWeight(this.repository);

  Future<Either<Failure, WeightEntity>> call({
    required int userId,
    required double weight,
    required String recordedDate,
    String? notes,
  }) async {
    return await repository.addWeight(
      userId: userId,
      weight: weight,
      recordedDate: recordedDate,
      notes: notes,
    );
  }
}
