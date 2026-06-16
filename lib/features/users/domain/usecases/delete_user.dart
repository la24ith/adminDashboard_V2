// domain/usecases/delete_user.dart

import 'package:dartz/dartz.dart';
import '../repositories/user_repository.dart';

class DeleteUser {
  final UserRepository repository;

  const DeleteUser(this.repository);

  Future<Either<Failure, void>> call(int userId) async {
    return await repository.deleteUser(userId);
  }
}
