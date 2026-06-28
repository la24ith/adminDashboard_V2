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
    // ✅ FIX #1: إضافة معامل لتجاوز الكاش عند الحاجة (مثلاً بعد الإضافة)
    bool forceRefresh = false,
  }) async {
    try {
      // 🔍 1. التحقق من الـ Cache (للصفحة الأولى فقط، وليس عند forceRefresh)
      if (enableCache &&
          page == 1 &&
          search == null &&
          status == null &&
          !forceRefresh) {
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

      // ✅ FIX #1: مسح الكاش القديم ثم حفظ الجديد
      if (enableCache && page == 1 && search == null && status == null) {
        await localDataSource.clearCache(); // امسح القديم أولاً
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

      // ✅ FIX #1: مسح الكاش بعد التحديث
      if (enableCache) await localDataSource.clearCache();

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

      // ✅ FIX #1: مسح الكاش بعد التمديد
      if (enableCache) await localDataSource.clearCache();

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
  Future<Either<Failure, UserEntity>> createUser(
      Map<String, dynamic> userData) async {
    try {
      final response = await dio.post(
        '/api/admin/users',
        data: userData,
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

      final userData2 = responseData['data'] ?? responseData;
      if (userData2 == null) {
        return Left(Failure(
          message: 'بيانات المستخدم غير موجودة',
          statusCode: response.statusCode,
        ));
      }

      // ✅ FIX #1: مسح الكاش فوراً بعد إنشاء مستخدم جديد
      if (enableCache) await localDataSource.clearCache();

      final user = UserEntity.fromJson(userData2);
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
  Future<Either<Failure, UserEntity>> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await dio.put(
        '/api/admin/users/$userId',
        data: userData,
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

      final userDataMap = responseData['data'] ?? responseData;
      if (userDataMap == null) {
        return Left(Failure(
          message: 'بيانات المستخدم غير موجودة',
          statusCode: response.statusCode,
        ));
      }

      // ✅ FIX #1: مسح الكاش بعد تحديث المستخدم
      if (enableCache) await localDataSource.clearCache();

      final user = UserEntity.fromJson(userDataMap);
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

      if (enableCache) await localDataSource.clearCache();

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

      if (enableCache) await localDataSource.clearCache();

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

      if (enableCache) await localDataSource.clearCache();

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

  @override
  Future<Either<Failure, void>> toggleScreenshot(
    int userId,
    bool currentStatus,
  ) async {
    try {
      final response = await dio.patch(
        '/api/admin/users/$userId/screenshot-permission',
        data: {'can_screenshot': !currentStatus},
      );

      if (response.statusCode != 200) {
        return Left(Failure(
          message: 'فشل تحديث صلاحية تصوير الشاشة',
          statusCode: response.statusCode,
        ));
      }

      if (enableCache) await localDataSource.clearCache(); // ✅ FIX: مسح الكاش بعد التغيير
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
  Future<Either<Failure, void>> deleteUser(int userId) async {
    try {
      await dio.delete('/api/admin/users/$userId');
      if (enableCache) await localDataSource.clearCache(); // ✅ FIX: مسح الكاش بعد الحذف
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
}
