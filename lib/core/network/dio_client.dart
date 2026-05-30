import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      validateStatus: (status) {
        // قبول جميع الـ status codes للتعامل معها يدوياً
        return status != null && status < 500;
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // إضافة التوكن إذا كان موجوداً
        final token = await AuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // ✅ تأكد من أن طريقة الطلب صحيحة
        print(
            '📡 Request: ${options.method} ${options.baseUrl}${options.path}');
        print('📦 Data: ${options.data}');
        print('🔑 Headers: ${options.headers}');

        return handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '✅ Response: ${response.statusCode} ${response.requestOptions.path}');
        print('📦 Response Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.message}');
        print('❌ Status Code: ${error.response?.statusCode}');
        print('❌ Response Data: ${error.response?.data}');

        if (error.response?.statusCode == 401) {
          AuthService.clearToken();
        }
        return handler.next(error);
      },
    ));

    return dio;
  }
}
