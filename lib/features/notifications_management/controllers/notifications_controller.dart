import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

class NotificationsController extends ChangeNotifier {
  // ✅ القائمة الآن من نوع NotificationModel بدل Map خام
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _error;
  String? _successMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;
  String? get successMessage => _successMessage;

  NotificationsController() {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminNotifications);

      if (response.statusCode == 200) {
        final rawList = List<Map<String, dynamic>>.from(
          response.data['data'] ?? response.data,
        );
        // ✅ تحويل فوري إلى NotificationModel — لا Map خام في أي مكان آخر
        _notifications =
            rawList.map((json) => NotificationModel.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('فشل تحميل الإشعارات');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNotification(Map<String, dynamic> notificationData) async {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.post(
        ApiConstants.adminNotifications,
        data: notificationData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _successMessage = notificationData.containsKey('send_at')
            ? 'تم جدولة الإشعار بنجاح'
            : 'تم إرسال الإشعار بنجاح';
        await loadNotifications();
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل إنشاء الإشعار');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotification(
    String notificationId,
    Map<String, dynamic> notificationData,
  ) async {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.put(
        '${ApiConstants.adminNotifications}/$notificationId',
        data: notificationData,
      );

      if (response.statusCode == 200) {
        _successMessage = 'تم تحديث الإشعار بنجاح';
        await loadNotifications();
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل تحديث الإشعار');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.delete(
        '${ApiConstants.adminNotifications}/$notificationId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // ✅ الحذف المحلي آمن الآن عبر id من NotificationModel
        _notifications.removeWhere((n) => n.id == notificationId);
        _successMessage = 'تم حذف الإشعار بنجاح';
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل حذف الإشعار');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> extendNotification(String notificationId, int days) async {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final endpoint = ApiConstants.adminNotificationsExtend
          .replaceAll('{notification_id}', notificationId);
      final response = await dio.put(endpoint, data: {'days': days});

      if (response.statusCode == 200) {
        _successMessage = 'تم تمديد صلاحية الإشعار بنجاح (+$days يوم)';
        await loadNotifications();
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل تمديد الإشعار');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendNow(String notificationId) async {
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.put(
        '${ApiConstants.adminNotifications}/$notificationId',
        data: {'send_at': DateTime.now().toIso8601String()},
      );

      if (response.statusCode == 200) {
        _successMessage = 'تم إرسال الإشعار بنجاح';
        await loadNotifications();
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل إرسال الإشعار');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
