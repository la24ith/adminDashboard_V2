import 'package:dartz/dartz.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, List<User>>> getUsers();
  Future<Either<Failure, User>> addUser(User user);
  Future<Either<Failure, User>> updateUser(User user);
  Future<Either<Failure, void>> deleteUser(int id);
  Future<Either<Failure, User>> extendSubscription(int id, DateTime newEndDate);
  Future<Either<Failure, User>> toggleMultiDevice(int id);
}

class Failure {
  final String message;
  const Failure(this.message);
}
