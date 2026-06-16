// domain/usecases/update_user.dart

import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateUser {
  final UserRepository repository;

  const UpdateUser(this.repository);

  Future<Either<Failure, UserEntity>> call(
    int userId,
    Map<String, dynamic> data,
  ) async {
    return await repository.updateUser(userId, data);
  }
}
