// domain/usecases/toggle_user_status.dart

import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class ToggleUserStatus {
  final UserRepository repository;

  const ToggleUserStatus(this.repository);

  Future<Either<Failure, UserEntity>> call(
    int userId,
    bool currentStatus,
  ) async {
    return await repository.toggleUserStatus(userId, currentStatus);
  }
}
