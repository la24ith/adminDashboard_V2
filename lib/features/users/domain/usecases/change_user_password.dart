// domain/usecases/change_user_password.dart

import 'package:dartz/dartz.dart';
import '../repositories/user_repository.dart';

class ChangeUserPassword {
  final UserRepository repository;

  const ChangeUserPassword(this.repository);

  Future<Either<Failure, void>> call(
    int userId,
    String newPassword,
  ) async {
    return await repository.changeUserPassword(userId, newPassword);
  }
}
