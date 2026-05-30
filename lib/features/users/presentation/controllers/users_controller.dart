import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class UsersController extends ChangeNotifier {
  List<Map<String, dynamic>> _users = [];
  bool _isDeleting = false;
  String? _deletingUserId;
  bool _isLoading = false;
  bool _isActionInProgress = false;

  String? _error;
  String? _successMessage;

  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  bool get isDeleting => _isDeleting;
  String? get deletingUserId => _deletingUserId;
  String? get error => _error;
  String? get successMessage => _successMessage;

  UsersController() {
    loadUsers();
  }

  // ✅ جلب تفاصيل الاشتراك الكاملة
  Future<Map<String, dynamic>?> getUserSubscriptionDetails(
      String userId) async {
    try {
      final dio = DioClient.instance;
      final response =
          await dio.get('/api/admin/users/$userId/subscription-details');

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting subscription details for user $userId: $e');
      return null;
    }
  }

  // ✅ تحميل المستخدمين
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminUsers);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        _users = List<Map<String, dynamic>>.from(data);

        for (int i = 0; i < _users.length; i++) {
          final userId = _users[i]['id'].toString();
          final subscriptionDetails = await getUserSubscriptionDetails(userId);

          if (subscriptionDetails != null) {
            if (subscriptionDetails['subscription'] != null) {
              final sub = subscriptionDetails['subscription'];
              _users[i]['subscription_start'] = sub['start_date'];
              _users[i]['subscription_end'] = sub['end_date'];
              _users[i]['subscription_status'] = sub['status'];
              _users[i]['plan_type'] = sub['plan_type'];
              _users[i]['price'] = double.parse(sub['price'].toString());
              _users[i]['max_devices'] = sub['max_devices'];
            }

            if (subscriptionDetails['computed'] != null) {
              final computed = subscriptionDetails['computed'];
              _users[i]['is_active_now'] = computed['is_active_now'];
              _users[i]['is_expired'] = computed['is_expired'];
              _users[i]['days_remaining'] = computed['days_remaining'];
              _users[i]['devices_used'] = computed['devices_used'];
              _users[i]['devices_remaining'] = computed['devices_remaining'];
            }

            if (subscriptionDetails['devices_summary'] != null) {
              final devicesSummary = subscriptionDetails['devices_summary'];
              _users[i]['total_devices'] = devicesSummary['total_devices'];
              _users[i]['approved_devices'] =
                  devicesSummary['approved_devices'];
              _users[i]['pending_devices'] = devicesSummary['pending_devices'];
              _users[i]['blocked_devices'] = devicesSummary['blocked_devices'];
            }
          }
        }
      } else {
        throw Exception('فشل تحميل المستخدمين');
      }
    } catch (e) {
      _error = _handleApiError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  void _startAction() {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void _finishAction() {
    _isActionInProgress = false;
    notifyListeners();
  }

  String _translateField(String field) {
    switch (field) {
      case 'name':
        return 'الاسم';
      case 'email':
        return 'البريد الإلكتروني';
      case 'password':
        return 'كلمة المرور';
      case 'phone':
        return 'رقم الهاتف';
      case 'role':
        return 'الدور';
      case 'ideal_weight':
        return 'الوزن المثالي';
      case 'target_weight':
        return 'الوزن المستهدف';
      case 'current_weight':
        return 'الوزن الحالي';
      case 'height':
        return 'الطول';
      default:
        return field;
    }
  }

  String _translateErrorMessage(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('email') &&
        (msg.contains('taken') || msg.contains('exists'))) {
      return 'البريد الإلكتروني مستخدم بالفعل';
    }
    if (msg.contains('password') && msg.contains('confirmation')) {
      return 'كلمة المرور وتأكيدها غير متطابقين';
    }
    if (msg.contains('password') && msg.contains('min')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (msg.contains('name') && msg.contains('required')) return 'الاسم مطلوب';
    if (msg.contains('email') && msg.contains('required'))
      return 'البريد الإلكتروني مطلوب';
    if (msg.contains('email') && msg.contains('invalid'))
      return 'البريد الإلكتروني غير صحيح';
    if (msg.contains('phone')) return 'رقم الهاتف غير صحيح';
    if (msg.contains('role')) return 'الدور المحدد غير صحيح';
    if (msg.contains('unauthenticated'))
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى';
    if (msg.contains('forbidden')) return 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
    if (msg.contains('timeout')) return 'انتهى وقت الاتصال. حاول مرة أخرى';
    if (msg.contains('network')) return 'حدث خطأ في الاتصال. تحقق من الإنترنت';
    return message;
  }

  // ✅ تحديث بيانات المستخدم
  Future<void> refreshUserData(String userId) async {
    try {
      final dio = DioClient.instance;
      final response = await dio.get('${ApiConstants.adminUsers}/$userId');

      if (response.statusCode == 200) {
        final updatedUser = response.data['data'] ?? response.data;
        final index = _users.indexWhere((u) => u['id'].toString() == userId);

        if (index != -1) {
          _users[index] = {..._users[index], ...updatedUser};
          final subscriptionDetails = await getUserSubscriptionDetails(userId);
          if (subscriptionDetails != null) {
            _updateUserSubscriptionData(index, subscriptionDetails);
          }
          _safeNotifyListeners();
        }
      }
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  void _updateUserSubscriptionData(
      int index, Map<String, dynamic> subscriptionDetails) {
    if (subscriptionDetails['subscription'] != null) {
      final sub = subscriptionDetails['subscription'];
      _users[index]['subscription_start'] = sub['start_date'];
      _users[index]['subscription_end'] = sub['end_date'];
      _users[index]['subscription_status'] = sub['status'];
      _users[index]['plan_type'] = sub['plan_type'];
      _users[index]['price'] = double.parse(sub['price'].toString());
      _users[index]['max_devices'] = sub['max_devices'];
    }

    if (subscriptionDetails['computed'] != null) {
      final computed = subscriptionDetails['computed'];
      _users[index]['is_active_now'] = computed['is_active_now'];
      _users[index]['is_expired'] = computed['is_expired'];
      _users[index]['days_remaining'] = computed['days_remaining'];
      _users[index]['devices_used'] = computed['devices_used'];
      _users[index]['devices_remaining'] = computed['devices_remaining'];
    }
  }

  // ✅ نسخة مبسطة - إنشاء مستخدم فقط بدون اشتراك
  // في users_controller.dart، قم بتحديث دوال معالجة الأخطاء

  String _handleApiError(dynamic error) {
    print('🔍 Raw error: $error');

    try {
      if (error is DioException) {
        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map) {
            // ✅ عرض رسائل التحقق من الصحة (Validation Errors)
            if (data.containsKey('errors') && data['errors'] is Map) {
              final errors = data['errors'] as Map;
              final messages = <String>[];

              // تجميع جميع رسائل الخطأ
              errors.forEach((field, fieldErrors) {
                if (fieldErrors is List && fieldErrors.isNotEmpty) {
                  // ترجمة اسم الحقل
                  final fieldName = _translateField(field);
                  messages.add('$fieldName: ${fieldErrors.first}');
                } else if (fieldErrors is String) {
                  final fieldName = _translateField(field);
                  messages.add('$fieldName: $fieldErrors');
                }
              });

              if (messages.isNotEmpty) {
                // عرض جميع الأخطاء في رسالة واحدة
                return messages.join('\n');
              }
            }

            // ✅ عرض رسالة الخطأ الرئيسية
            if (data.containsKey('message')) {
              final message = data['message'];
              if (message is String && message.isNotEmpty) {
                return _translateErrorMessage(message);
              }
            }
          }
        }

        // أخطاء الاتصال
        if (error.type == DioExceptionType.connectionTimeout) {
          return 'انتهى وقت الاتصال. تأكد من اتصالك بالإنترنت';
        }
        if (error.type == DioExceptionType.receiveTimeout) {
          return 'انتهى وقت الاستجابة. حاول مرة أخرى';
        }
        if (error.type == DioExceptionType.connectionError) {
          return 'لا يمكن الاتصال بالخادم. تأكد من اتصالك بالإنترنت';
        }
      }

      if (error is Map) {
        if (error.containsKey('errors') && error['errors'] is Map) {
          final errors = error['errors'] as Map;
          final messages = <String>[];
          errors.forEach((field, fieldErrors) {
            if (fieldErrors is List && fieldErrors.isNotEmpty) {
              final fieldName = _translateField(field);
              messages.add('$fieldName: ${fieldErrors.first}');
            }
          });
          if (messages.isNotEmpty) return messages.join('\n');
        }
        if (error.containsKey('message')) {
          return _translateErrorMessage(error['message']);
        }
      }

      if (error is String) {
        return _translateErrorMessage(error);
      }

      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    } catch (e) {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }

// ✅ تحسين دالة createUser لعرض رسائل الخطأ بشكل أفضل
  Future<bool> createUser(Map<String, dynamic> userData) async {
    _startAction();

    try {
      final dio = DioClient.instance;

      // تنظيف البيانات قبل الإرسال
      final Map<String, dynamic> cleanUserData = {};
      userData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanUserData[key] = value;
        }
      });

      print('📤 Creating user with data: $cleanUserData');

      final response = await dio.post(
        ApiConstants.adminUsers,
        data: cleanUserData,
        options: Options(
          validateStatus: (status) =>
              status! < 500, // قبول جميع الأخطاء تحت 500
        ),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newUser = response.data['data'] ?? response.data;
        _users.insert(0, newUser);
        _successMessage = 'تم إنشاء المستخدم بنجاح';
        _finishAction();
        _safeNotifyListeners();
        return true;
      } else {
        // معالجة أخطاء الـ API
        final errorMessage = _extractErrorMessage(response.data);
        _error = errorMessage;
        _finishAction();
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      _error = _handleApiError(e);
      _finishAction();
      _safeNotifyListeners();
      return false;
    }
  }

// ✅ دالة مساعدة لاستخراج رسالة الخطأ من الـ Response
  String _extractErrorMessage(dynamic data) {
    try {
      if (data is Map) {
        // رسائل التحقق (Validation Errors)
        if (data.containsKey('errors') && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final messages = <String>[];

          errors.forEach((field, fieldErrors) {
            final fieldName = _translateField(field);
            if (fieldErrors is List && fieldErrors.isNotEmpty) {
              messages.add('• $fieldName: ${fieldErrors.first}');
            } else if (fieldErrors is String) {
              messages.add('• $fieldName: $fieldErrors');
            }
          });

          if (messages.isNotEmpty) {
            return 'يرجى تصحيح الأخطاء التالية:\n${messages.join('\n')}';
          }
        }

        // رسالة الخطأ الرئيسية
        if (data.containsKey('message')) {
          final message = data['message'];
          if (message is String && message.isNotEmpty) {
            return _translateErrorMessage(message);
          }
        }
      }

      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    } catch (e) {
      return 'حدث خطأ أثناء معالجة الطلب';
    }
  }

// ✅ تحسين دالة updateUser
  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    _startAction();

    try {
      final dio = DioClient.instance;

      // تنظيف البيانات
      final Map<String, dynamic> cleanUserData = {};
      userData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanUserData[key] = value;
        }
      });

      final response = await dio.put(
        '${ApiConstants.adminUsers}/$userId',
        data: cleanUserData,
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final updatedUser = response.data['data'] ?? response.data;
        final index = _users.indexWhere((u) => u['id'].toString() == userId);
        if (index != -1) {
          _users[index] = {..._users[index], ...updatedUser};
        }
        _successMessage = 'تم تحديث المستخدم بنجاح';
        _finishAction();
        _safeNotifyListeners();
        return true;
      } else {
        final errorMessage = _extractErrorMessage(response.data);
        _error = errorMessage;
        _finishAction();
        _safeNotifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      _error = _handleApiError(e);
      _finishAction();
      _safeNotifyListeners();
      return false;
    }
  }

  // ✅ حذف مستخدم
  Future<bool> deleteUser(String userId) async {
    _isDeleting = true;
    _deletingUserId = userId;
    _safeNotify();

    try {
      final dio = DioClient.instance;
      final response = await dio.delete('${ApiConstants.adminUsers}/$userId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _users.removeWhere((user) => user['id'].toString() == userId);
        _successMessage = 'تم حذف المستخدم بنجاح';
        await _saveSubscriptionsLocally();

        _isDeleting = false;
        _deletingUserId = null;
        _safeNotify();
        return true;
      }
      throw Exception('فشل حذف المستخدم');
    } catch (e) {
      _error = _handleApiError(e);
      _isDeleting = false;
      _deletingUserId = null;
      _safeNotify();
      return false;
    }
  }

  // ✅ تبديل حالة المستخدم
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    _startAction();

    try {
      final dio = DioClient.instance;
      final endpoint =
          ApiConstants.adminUserStatus.replaceAll('{user_id}', userId);
      final response = await dio.put(endpoint, data: {'is_active': !isActive});

      if (response.statusCode == 200) {
        final index = _users.indexWhere((u) => u['id'].toString() == userId);
        if (index != -1) {
          _users[index]['is_active'] = !isActive;
        }
        _successMessage = !isActive ? 'تم تفعيل المستخدم' : 'تم تعليق المستخدم';
        _finishAction();
        return true;
      }
      throw Exception('فشل تغيير حالة المستخدم');
    } catch (e) {
      _error = _handleApiError(e);
      _finishAction();
      return false;
    }
  }

  // ✅ تبديل وضع الأجهزة المتعددة
  Future<bool> toggleMultiDevice(String userId, bool currentStatus) async {
    _startAction();

    try {
      final dio = DioClient.instance;
      final endpoint =
          ApiConstants.adminUserDevices.replaceAll('{user_id}', userId);
      final response =
          await dio.post('$endpoint/toggle', data: {'enabled': !currentStatus});

      if (response.statusCode == 200) {
        _successMessage = !currentStatus
            ? 'تم تفعيل الأجهزة المتعددة'
            : 'تم تعطيل الأجهزة المتعددة';
        await loadUsers();
        _finishAction();
        return true;
      }
      throw Exception('فشل تغيير إعداد الأجهزة');
    } catch (e) {
      _error = _handleApiError(e);
      _finishAction();
      return false;
    }
  }

  // ✅ إنشاء اشتراك

  // ✅ تمديد الاشتراك
  Future<bool> extendSubscription(String userId, int days) async {
    _startAction();

    try {
      final dio = DioClient.instance;
      final endpoint = '/api/admin/users/$userId/extend-subscription';
      final response = await dio.post(endpoint, data: {'days': days});

      if (response.statusCode == 200) {
        final subscription = response.data['subscription'];
        final computed = response.data['computed'];

        final index = _users.indexWhere((u) => u['id'].toString() == userId);
        if (index != -1) {
          if (subscription != null) {
            _users[index]['subscription_end'] = subscription['end_date'];
            _users[index]['subscription_start'] = subscription['start_date'];
            _users[index]['subscription_status'] = subscription['status'];
          }
          if (computed != null) {
            _users[index]['days_remaining'] = computed['days_remaining'];
            _users[index]['is_expired'] = computed['is_expired'];
            _users[index]['is_active_now'] = computed['is_active_now'];
          }
          await refreshUserData(userId);
        }

        _successMessage = 'تم تمديد الاشتراك بنجاح (+$days يوماً)';
        await _saveSubscriptionsLocally();
        _finishAction();
        _safeNotifyListeners();
        return true;
      } else if (response.statusCode == 404) {
        _error = 'المستخدم ليس لديه اشتراك نشط';
        _finishAction();
        return false;
      } else {
        throw Exception('فشل تمديد الاشتراك');
      }
    } catch (e) {
      _error = _handleApiError(e);
      _finishAction();
      return false;
    }
  }

  // ✅ تحديث الاشتراك
  Future<bool> updateSubscription(
    String userId, {
    required DateTime startDate,
    required DateTime endDate,
    String planType = 'monthly',
    String status = 'active',
    double price = 199.99,
    int maxDevices = 1,
  }) async {
    _startAction();

    try {
      final dio = DioClient.instance;
      final endpoint = '/api/admin/users/$userId/subscription';

      final data = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'plan_type': planType,
        'status': status,
        'price': price,
        'max_devices': maxDevices,
      };

      final response = await dio.put(endpoint, data: data);

      if (response.statusCode == 200) {
        final subscription = response.data['subscription'] ?? response.data;
        final computed = response.data['computed'];

        final index = _users.indexWhere((u) => u['id'].toString() == userId);
        if (index != -1) {
          _users[index]['subscription_start'] = subscription['start_date'];
          _users[index]['subscription_end'] = subscription['end_date'];
          _users[index]['subscription_status'] = subscription['status'];
          _users[index]['plan_type'] = subscription['plan_type'];
          _users[index]['price'] =
              double.parse(subscription['price'].toString());
          _users[index]['max_devices'] = subscription['max_devices'];

          if (computed != null) {
            _users[index]['days_remaining'] = computed['days_remaining'];
            _users[index]['is_expired'] = computed['is_expired'];
            _users[index]['is_active_now'] = computed['is_active_now'];
            _users[index]['devices_used'] = computed['devices_used'];
            _users[index]['devices_remaining'] = computed['devices_remaining'];
          }

          await refreshUserData(userId);
        }

        _successMessage = 'تم تحديث الاشتراك بنجاح';
        await _saveSubscriptionsLocally();
        _finishAction();
        _safeNotifyListeners();
        return true;
      } else {
        throw Exception('فشل تحديث الاشتراك');
      }
    } catch (e) {
      _error = _handleApiError(e);
      _finishAction();
      return false;
    }
  }

  Future<void> _saveSubscriptionsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionsMap = <String, dynamic>{};

    for (var user in _users) {
      final userId = user['id'].toString();
      if (user.containsKey('subscription_end') &&
          user['subscription_end'] != null) {
        subscriptionsMap[userId] = {
          'subscription_start': user['subscription_start'],
          'subscription_end': user['subscription_end'],
          'subscription_status': user['subscription_status'],
          'plan_type': user['plan_type'],
          'price': user['price'],
          'max_devices': user['max_devices'],
        };
      }
    }

    await prefs.setString('subscriptions', jsonEncode(subscriptionsMap));
  }

  void _safeNotify() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  void _safeNotifyListeners() {
    try {
      if (hasListeners) {
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error notifying listeners: $e');
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
