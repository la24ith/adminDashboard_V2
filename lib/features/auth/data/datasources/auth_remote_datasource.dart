import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = DioClient.instance;

  /// ✅ تسجيل دخول الأدمن (أو أي مستخدم)
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('📍 DataSource: Sending POST request to ${ApiConstants.login}');
      print('📍 DataSource: Request data: ${request.toJson()}');
      
      final response = await _dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );

      print('📍 DataSource: Response status: ${response.statusCode}');
      print('📍 DataSource: Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        
        // ✅ استخراج التوكن من المفتاح 'data' (حسب تنسيق الـ API)
        String token;
        if (responseData['data'] != null && responseData['data']['token'] != null) {
          token = responseData['data']['token'];
        } else if (responseData['token'] != null) {
          token = responseData['token'];
        } else {
          print('❌ DataSource: Token not found in response!');
          throw Exception('لم يتم العثور على التوكن في الرد');
        }
        
        print('✅ DataSource: Token extracted successfully');
        return LoginResponse.fromJson(responseData);
      } else {
        throw Exception('فشل تسجيل الدخول: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DataSource: Dio error - ${e.message}');
      print('❌ DataSource: Response - ${e.response?.data}');
      
      if (e.response != null) {
        final message = e.response?.data['message'] ?? 
                        e.response?.data['error'] ??
                        'فشل الاتصال بالسيرفر';
        throw Exception(message);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('انتهى وقت الاتصال');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('انتهى وقت الاستجابة');
      } else {
        throw Exception('خطأ في الاتصال: ${e.message}');
      }
    }
  }

  /// ✅ تسجيل الخروج
  Future<void> logout() async {
    try {
      print('📍 DataSource: Sending POST request to ${ApiConstants.logout}');
      
      final response = await _dio.post(ApiConstants.logout);
      
      print('📍 DataSource: Logout response status: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DataSource: Logout error - ${e.message}');
    }
  }

  /// ✅ جلب بيانات المستخدم الحالي (للأدمن أو المريض)
  Future<UserData> getCurrentUser() async {
    try {
      print('📍 DataSource: Sending GET request to ${ApiConstants.user}');
      
      final response = await _dio.get(ApiConstants.user);
      
      print('📍 DataSource: Get user response status: ${response.statusCode}');
      
      final responseData = response.data['data'] ?? response.data;
      return UserData.fromJson(responseData);
    } on DioException catch (e) {
      print('❌ DataSource: Get user error - ${e.message}');
      throw Exception('فشل في جلب بيانات المستخدم');
    }
  }
}