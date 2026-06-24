// data/repositories/user_repository_impl.dart

import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/features/users/domain/entities/weight_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/entities/user_subscription_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';
import '../models/paginated_response.dart';

class UserRepositoryImpl implements UserRepository {
  final Dio dio;
  final UserLocalDataSource localDataSource;
  final bool enableCache;

  UserRepositoryImpl({
    required this.dio,
    required this.localDataSource,
    this.enableCache = true,
  });

  @override
  Future<Either<Failure, PaginatedUserSubscriptions>> getSubscriptions({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    try {
      // 🔍 1. التحقق من الـ Cache (للصفحة الأولى فقط)
      if (enableCache && page == 1 && search == null && status == null) {
        final cached = await localDataSource.getCachedSubscriptions();
        if (cached != null) {
          return Right(cached);
        }
      }

      // 🌐 2. جلب البيانات من الـ API
      final response = await dio.get(
        ApiConstants.subscriptions,
        queryParameters: {
          ApiConstants.perPage: perPage,
          ApiConstants.page: page,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );

      // ✅ التحقق من وجود data
      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      // ✅ التحقق من وجود مفتاح 'data' في الـ Response
      if (!responseData.containsKey('data') || responseData['data'] == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للمستخدمين',
          statusCode: response.statusCode,
        ));
      }

      final paginatedResponse =
          PaginatedResponse<Map<String, dynamic>>.fromJson(
        responseData,
        (json) => json,
      );

      // 🗂️ 4. تحويل إلى Entities
      final entities = paginatedResponse.data.map((item) {
        return UserSubscriptionEntity.fromJson(item);
      }).toList();

      final result = PaginatedUserSubscriptions(
        currentPage: paginatedResponse.currentPage,
        data: entities,
        lastPage: paginatedResponse.lastPage,
        total: paginatedResponse.total,
        perPage: paginatedResponse.perPage,
        hasMore: paginatedResponse.hasMore,
      );

      // 💾 5. حفظ في الـ Cache
      if (enableCache && page == 1 && search == null && status == null) {
        await localDataSource.cacheSubscriptions(result);
      }

      return Right(result);
    } on DioException catch (e) {
      final errorMessage = _handleDioError(e);
      return Left(Failure(
        message: errorMessage,
        statusCode: e.response?.statusCode,
        errors: e.response?.data,
      ));
    } catch (e) {
      return Left(Failure(
        message: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, UserSubscriptionEntity>> getUserSubscription(
      int userId) async {
    try {
      final response = await dio.get(
        '${ApiConstants.subscriptions}/$userId',
      );

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للمستخدم',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      final model = UserSubscriptionEntity.fromJson(responseData);
      return Right(model);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> updateSubscription(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/api/admin/users/$userId/subscription',
        data: data,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      // ✅ التحقق من وجود data
      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للاشتراك',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      // ✅ التحقق: البيانات قد تكون مباشرة أو داخل 'subscription'
      Map<String, dynamic> subscriptionData;

      // إذا كان الـ Response يحتوي على مفتاح 'subscription'
      if (responseData.containsKey('subscription') &&
          responseData['subscription'] != null) {
        subscriptionData = responseData['subscription'] as Map<String, dynamic>;
      } else {
        // ✅ البيانات مباشرة (كما في الـ Logs)
        subscriptionData = responseData;
      }

      // ✅ التحقق من وجود البيانات الأساسية للاشتراك
      if (!subscriptionData.containsKey('id') ||
          subscriptionData['id'] == null) {
        return Left(Failure(
          message: 'بيانات الاشتراك غير مكتملة',
          statusCode: response.statusCode,
        ));
      }

      final subscription = SubscriptionEntity.fromJson(subscriptionData);
      return Right(subscription);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> extendSubscription(
    int userId,
    int days,
  ) async {
    try {
      final response = await dio.post(
        '/api/admin/users/$userId/extend-subscription',
        data: {'days': days},
      );

      print('📥 Extend Response status: ${response.statusCode}');
      print('📥 Extend Response data: ${response.data}');

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للاشتراك',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      // ✅ التحقق: البيانات قد تكون مباشرة أو داخل 'subscription'
      Map<String, dynamic> subscriptionData;

      if (responseData.containsKey('subscription') &&
          responseData['subscription'] != null) {
        subscriptionData = responseData['subscription'] as Map<String, dynamic>;
      } else {
        subscriptionData = responseData;
      }

      if (!subscriptionData.containsKey('id') ||
          subscriptionData['id'] == null) {
        return Left(Failure(
          message: 'بيانات الاشتراك غير مكتملة',
          statusCode: response.statusCode,
        ));
      }

      final subscription = SubscriptionEntity.fromJson(subscriptionData);
      return Right(subscription);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int userId) async {
    try {
      await dio.delete('/api/admin/users/$userId');
      return const Right(null);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(
    int userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put(
        '/api/admin/users/$userId',
        data: data,
      );

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للمستخدم',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      final userData = responseData['data'] ?? responseData;
      if (userData == null) {
        return Left(Failure(
          message: 'بيانات المستخدم غير موجودة',
          statusCode: response.statusCode,
        ));
      }

      final user = UserEntity.fromJson(userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser(
      Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '/api/admin/users',
        data: data,
      );

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للمستخدم',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      final userData = responseData['data'] ?? responseData;
      if (userData == null) {
        return Left(Failure(
          message: 'بيانات المستخدم غير موجودة',
          statusCode: response.statusCode,
        ));
      }

      final user = UserEntity.fromJson(userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> toggleUserStatus(
    int userId,
    bool currentStatus,
  ) async {
    try {
      final response = await dio.put(
        '/api/admin/users/$userId/status',
        data: {'is_active': !currentStatus},
      );

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للمستخدم',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      final userData = responseData['data'] ?? responseData;
      if (userData == null) {
        return Left(Failure(
          message: 'بيانات المستخدم غير موجودة',
          statusCode: response.statusCode,
        ));
      }

      final user = UserEntity.fromJson(userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionEntity>> toggleMultiDevice(
    int userId,
    bool currentStatus,
  ) async {
    try {
      final response = await dio.post(
        '/api/admin/users/$userId/devices/toggle',
        data: {'enabled': !currentStatus},
      );

      if (response.data == null) {
        return Left(Failure(
          message: 'لا توجد بيانات للاشتراك',
          statusCode: response.statusCode,
        ));
      }

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        return Left(Failure(
          message: 'تنسيق البيانات غير صحيح',
          statusCode: response.statusCode,
        ));
      }

      // ✅ التحقق: البيانات قد تكون مباشرة أو داخل 'subscription'
      Map<String, dynamic> subscriptionData;

      if (responseData.containsKey('subscription') &&
          responseData['subscription'] != null) {
        subscriptionData = responseData['subscription'] as Map<String, dynamic>;
      } else {
        subscriptionData = responseData;
      }

      if (!subscriptionData.containsKey('id') ||
          subscriptionData['id'] == null) {
        return Left(Failure(
          message: 'بيانات الاشتراك غير مكتملة',
          statusCode: response.statusCode,
        ));
      }

      final subscription = SubscriptionEntity.fromJson(subscriptionData);
      return Right(subscription);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  // 🛠️ Helper method لمعالجة أخطاء الـ Dio
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] ?? 'حدث خطأ في الخادم';
      }
      if (data is Map && data.containsKey('errors')) {
        final errors = data['errors'] as Map;
        final messages =
            errors.values.whereType<List>().expand((list) => list).join('\n');
        return messages.isNotEmpty ? messages : 'حدث خطأ في التحقق من البيانات';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'انتهى وقت الاتصال. تأكد من اتصالك بالإنترنت';
      case DioExceptionType.receiveTimeout:
        return 'انتهى وقت الاستجابة. حاول مرة أخرى';
      case DioExceptionType.connectionError:
        return 'لا يمكن الاتصال بالخادم. تأكد من اتصالك بالإنترنت';
      default:
        return e.message ?? 'حدث خطأ غير متوقع';
    }
  }

  @override
  Future<Either<Failure, WeightEntity>> addWeight({
    required int userId,
    required double weight,
    required String recordedDate,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '/api/admin/users/$userId/weight-records',
        data: {
          'weight': weight,
          'recorded_date': recordedDate,
          'notes': notes ?? 'From admin',
        },
      );

      final weightData = response.data['data'] ?? response.data;
      final weightEntity = WeightEntity.fromJson(weightData);

      // مسح الكاش بعد إضافة وزن جديد
      if (enableCache) {
        await localDataSource.clearCache();
      }

      return Right(weightEntity);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
        errors: e.response?.data,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  // ✅ 🆕 جلب تاريخ الأوزان لمستخدم
  @override
  Future<Either<Failure, List<WeightEntity>>> getUserWeightHistory(
    int userId, {
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '/api/admin/users/$userId/weight-records',
        queryParameters: {
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final weights = data.map((item) => WeightEntity.fromJson(item)).toList();

      return Right(weights);
    } on DioException catch (e) {
      return Left(Failure(
        message: _handleDioError(e),
        statusCode: e.response?.statusCode,
      ));
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }
}
