import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class ToggleMultiDevice {
  final UserRepository repository;

  const ToggleMultiDevice(this.repository);

  Future<Either<Failure, User>> call(int id) async {
    return await repository.toggleMultiDevice(id);
  }
}
