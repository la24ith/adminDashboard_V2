import 'package:admin_dashboard/features/auth/data/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_model.dart';
import '../../../../core/services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
Future<Either<Failure, User>> login(String email, String password) async {
  try {
    print('📍 Login attempt: $email');
    
    final request = LoginRequest(email: email, password: password);
    final response = await remoteDataSource.login(request);
    
    print('📍 Login response received');
    print('📍 Token: ${response.token.substring(0, 20)}...');
    print('📍 User: ${response.user.name} (${response.user.role})');
    
    final user = User(
      id: response.user.id,
      name: response.user.name,
      email: response.user.email,
      role: response.user.role,
      isActive: response.user.isActive,
      token: response.token,
    );
    
    // ✅ حفظ الجلسة (يبقى مسجل الدخول حتى بعد إغلاق التطبيق)
    await AuthService.saveToken(response.token);
    await AuthService.saveUser(user);
    
    print('📍 Session saved successfully');
    return Right(user);
  } catch (e) {
    print('❌ Login error: $e');
    return Left(Failure(e.toString()));
  }
}

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await AuthService.clearSession();
      return const Right(null);
    } catch (e) {
      await AuthService.clearSession();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userData = await remoteDataSource.getCurrentUser();
      
      final user = User(
        id: userData.id,
        name: userData.name,
        email: userData.email,
        role: userData.role,
        isActive: userData.isActive,
      );
      
      return Right(user);
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}