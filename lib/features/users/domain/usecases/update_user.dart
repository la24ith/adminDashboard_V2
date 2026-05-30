import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class UpdateUser {
  final UserRepository repository;

  const UpdateUser(this.repository);

  Future<Either<Failure, User>> call(User user) async {
    return await repository.updateUser(user);
  }
}
