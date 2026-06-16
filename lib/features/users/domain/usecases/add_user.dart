// domain/usecases/create_user.dart

import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class CreateUser {
  final UserRepository repository;

  const CreateUser(this.repository);

  Future<Either<Failure, UserEntity>> call(Map<String, dynamic> data) async {
    return await repository.createUser(data);
  }
}
