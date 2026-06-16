// domain/usecases/get_subscriptions.dart

import 'package:dartz/dartz.dart';
import '../entities/user_subscription_entity.dart';
import '../repositories/user_repository.dart';

class GetSubscriptions {
  final UserRepository repository;

  const GetSubscriptions(this.repository);

  Future<Either<Failure, PaginatedUserSubscriptions>> call({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    return await repository.getSubscriptions(
      page: page,
      perPage: perPage,
      search: search,
      status: status,
    );
  }
}
