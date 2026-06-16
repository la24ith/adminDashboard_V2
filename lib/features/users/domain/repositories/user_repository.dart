// domain/repositories/user_repository.dart

import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../entities/subscription_entity.dart';
import '../entities/user_subscription_entity.dart';

class Failure {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const Failure({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class PaginatedUserSubscriptions {
  final int currentPage;
  final List<UserSubscriptionEntity> data;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasMore;

  PaginatedUserSubscriptions({
    required this.currentPage,
    required this.data,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasMore,
  });
}

abstract class UserRepository {
  // ✅ جلب المستخدمين مع Pagination
  Future<Either<Failure, PaginatedUserSubscriptions>> getSubscriptions({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  });

  // ✅ جلب مستخدم واحد مع اشتراكه
  Future<Either<Failure, UserSubscriptionEntity>> getUserSubscription(
      int userId);

  // ✅ تحديث الاشتراك
  Future<Either<Failure, SubscriptionEntity>> updateSubscription(
    int userId,
    Map<String, dynamic> data,
  );

  // ✅ تمديد الاشتراك
  Future<Either<Failure, SubscriptionEntity>> extendSubscription(
    int userId,
    int days,
  );

  // ✅ حذف مستخدم
  Future<Either<Failure, void>> deleteUser(int userId);

  // ✅ تحديث مستخدم
  Future<Either<Failure, UserEntity>> updateUser(
    int userId,
    Map<String, dynamic> data,
  );

  // ✅ إنشاء مستخدم
  Future<Either<Failure, UserEntity>> createUser(Map<String, dynamic> data);

  // ✅ تبديل حالة المستخدم
  Future<Either<Failure, UserEntity>> toggleUserStatus(
    int userId,
    bool currentStatus,
  );

  // ✅ تبديل وضع الأجهزة المتعددة
  Future<Either<Failure, SubscriptionEntity>> toggleMultiDevice(
    int userId,
    bool currentStatus,
  );
}
