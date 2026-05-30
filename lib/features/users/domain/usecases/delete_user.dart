import 'package:dartz/dartz.dart';
import '../repositories/user_repository.dart';

class DeleteUser {
  final UserRepository repository;

  const DeleteUser(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteUser(id);
  }
}
