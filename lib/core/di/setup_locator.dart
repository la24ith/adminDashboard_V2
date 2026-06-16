import 'package:admin_dashboard/core/network/dio_client.dart';
import 'package:admin_dashboard/features/users/data/datasources/user_local_datasource.dart';
import 'package:admin_dashboard/features/users/data/repositories/user_repository_impl.dart';
import 'package:admin_dashboard/features/users/domain/repositories/user_repository.dart';
import 'package:admin_dashboard/features/users/domain/usecases/add_user.dart';
import 'package:admin_dashboard/features/users/domain/usecases/delete_user.dart';
import 'package:admin_dashboard/features/users/domain/usecases/extend_subscription.dart';
import 'package:admin_dashboard/features/users/domain/usecases/get_subscriptions.dart';
import 'package:admin_dashboard/features/users/domain/usecases/toggle_multi_device.dart';
import 'package:admin_dashboard/features/users/domain/usecases/toggle_user_status.dart';
import 'package:admin_dashboard/features/users/domain/usecases/update_subscription.dart';
import 'package:admin_dashboard/features/users/domain/usecases/update_user.dart';
import 'package:admin_dashboard/features/users/presentation/controllers/users_controller.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ✅ Shared Preferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ✅ Dio Client (استخدام الـ Dio من DioClient)
  sl.registerLazySingleton<Dio>(() => DioClient.instance);

  // ✅ Local Data Source
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSource(sl()),
  );

  // ✅ Repository
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      dio: sl(), // ✅ استخدام الـ Dio المسجل
      localDataSource: sl(),
      enableCache: true,
    ),
  );

  // ✅ Use Cases
  sl.registerLazySingleton(() => GetSubscriptions(sl()));
  sl.registerLazySingleton(() => CreateUser(sl()));
  sl.registerLazySingleton(() => UpdateUser(sl()));
  sl.registerLazySingleton(() => DeleteUser(sl()));
  sl.registerLazySingleton(() => ExtendSubscription(sl()));
  sl.registerLazySingleton(() => UpdateSubscription(sl()));
  sl.registerLazySingleton(() => ToggleUserStatus(sl()));
  sl.registerLazySingleton(() => ToggleMultiDevice(sl()));

  // ✅ Controllers
  sl.registerFactory(
    () => UsersController(
      getSubscriptionsUseCase: sl(),
      createUserUseCase: sl(),
      updateUserUseCase: sl(),
      deleteUserUseCase: sl(),
      extendSubscriptionUseCase: sl(),
      updateSubscriptionUseCase: sl(),
      toggleUserStatusUseCase: sl(),
      toggleMultiDeviceUseCase: sl(),
    ),
  );
}
