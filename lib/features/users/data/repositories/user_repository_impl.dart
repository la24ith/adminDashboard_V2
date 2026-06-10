import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<User>>> getUsers() async {
    try {
      final users = localDataSource.getUsers();
      return Right(users.map((u) => u.toEntity()).toList());
    } catch (e) {
      return Left(Failure('Failed to load users: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> addUser(User user) async {
    try {
      final newUser = UserModel.fromEntity(user);
      localDataSource.addUser(newUser);
      return Right(user);
    } catch (e) {
      return Left(Failure('Failed to add user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUser(User user) async {
    try {
      final updatedUser = UserModel.fromEntity(user);
      localDataSource.updateUser(updatedUser);
      return Right(user);
    } catch (e) {
      return Left(Failure('Failed to update user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int id) async {
    try {
      localDataSource.deleteUser(id);
      return const Right(null);
    } catch (e) {
      return Left(Failure('Failed to delete user: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> extendSubscription(
      int id, DateTime newEndDate) async {
    try {
      final users = localDataSource.getUsers();
      final user = users.firstWhere((u) => u.id == id);

      final updatedUser = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        subscriptionStart: user.subscriptionStart,
        subscriptionEnd: newEndDate,
        isActive: true,
        multiDeviceEnabled: user.multiDeviceEnabled,
      );

      localDataSource.updateUser(updatedUser);
      return Right(updatedUser.toEntity());
    } catch (e) {
      return Left(Failure('Failed to extend subscription: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> toggleMultiDevice(int id) async {
    try {
      final users = localDataSource.getUsers();
      final user = users.firstWhere((u) => u.id == id);

      final updatedUser = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        subscriptionStart: user.subscriptionStart,
        subscriptionEnd: user.subscriptionEnd,
        isActive: user.isActive,
        multiDeviceEnabled: !user.multiDeviceEnabled,
      );

      localDataSource.updateUser(updatedUser);
      return Right(updatedUser.toEntity());
    } catch (e) {
      return Left(Failure('Failed to toggle multi-device: ${e.toString()}'));
    }
  }
}
