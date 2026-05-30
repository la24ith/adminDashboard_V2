import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class ExtendSubscription {
  final UserRepository repository;

  const ExtendSubscription(this.repository);

  Future<Either<Failure, User>> call(String id, DateTime newEndDate) async {
    return await repository.extendSubscription(id, newEndDate);
  }
}
