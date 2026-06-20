import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/network/dio_client.dart';
import 'package:flutter/material.dart';

class DeviceManagementController extends ChangeNotifier {
  List<Map<String, dynamic>> _allDevices = [];
  List<Map<String, dynamic>> _usersWithDevices = [];
  bool _isLoading = true;
  String? _error;
  String? _approvingDeviceId;

  // ✅ متغير لتخزين أجهزة المستخدم الحالي
  List<Map<String, dynamic>> _currentUserDevices = [];

  // Getters
  List<Map<String, dynamic>> get allDevices => _allDevices;
  List<Map<String, dynamic>> get usersWithDevices => _usersWithDevices;

  // ✅ Getter لأجهزة المستخدم الحالي
  List<Map<String, dynamic>> get currentUserDevices => _currentUserDevices;

  // أجهزة بانتظار الموافقة
  List<Map<String, dynamic>> get pendingDevices {
    final List<Map<String, dynamic>> pending = [];

    for (final user in _usersWithDevices) {
      final userDevices = user['devices'] as List? ?? [];
      for (final device in userDevices) {
        final isApproved =
            device['is_approved'] == true || device['approved'] == true;
        final isBlocked =
            device['is_blocked'] == true || device['blocked'] == true;
        if (!isApproved && !isBlocked) {
          pending.add({
            ...device,
            'user_name': user['name'],
            'user_email': user['email'],
            'user_id': user['id'],
          });
        }
      }
    }

    return pending;
  }

  // الأجهزة النشطة
  List<Map<String, dynamic>> get approvedDevices {
    final List<Map<String, dynamic>> approved = [];

    for (final user in _usersWithDevices) {
      final userDevices = user['devices'] as List? ?? [];
      for (final device in userDevices) {
        final isApproved =
            device['is_approved'] == true || device['approved'] == true;
        final isBlocked =
            device['is_blocked'] == true || device['blocked'] == true;
        if (isApproved && !isBlocked) {
          approved.add({
            ...device,
            'user_name': user['name'],
            'user_email': user['email'],
            'user_id': user['id'],
          });
        }
      }
    }

    return approved;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get isApproving => _approvingDeviceId;

  // تحميل جميع البيانات
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('🚀 Starting to load all data...');

    await loadUsersWithDevices();
    _collectAllDevicesFromUsers();

    _isLoading = false;
    notifyListeners();

    debugPrint(
      '✅ Data loading completed. Devices: ${_allDevices.length}, Users: ${_usersWithDevices.length}',
    );
  }

  void _collectAllDevicesFromUsers() {
    _allDevices = [];

    for (final item in _usersWithDevices) {
      final user = item['user'] ?? {};
      final subscription = item['subscription'] ?? {};
      final devicesSummary = item['devices_summary'] ?? {};

      // إنشاء "تمثيل جهاز منطقي" من البيانات الحالية
      _allDevices.add({
        'user_id': user['id'],
        'user_name': user['name'],
        'user_email': user['email'],
        'subscription_status': subscription['status'],
        'plan_type': subscription['plan_type'],
        'total_devices': devicesSummary['total_devices'],
        'approved_devices': devicesSummary['approved_devices'],
        'pending_devices': devicesSummary['pending_devices'],
        'blocked_devices': devicesSummary['blocked_devices'],
        'devices_used': item['computed']?['devices_used'],
        'devices_remaining': item['computed']?['devices_remaining'],
      });
    }

    debugPrint(
      '📊 Devices summary generated: ${_allDevices.length} records from users',
    );
  }

  // جلب المستخدمين مع أجهزتهم
  Future<void> loadUsersWithDevices() async {
    try {
      final dio = DioClient.instance;

      debugPrint(
          '📡 Calling API: GET ${ApiConstants.allusersinfo}?per_page=100');

      final response = await dio.get(
        ApiConstants.allusersinfo,
        queryParameters: {'per_page': 100},
      );

      debugPrint('📡 Users response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['data'] is List) {
          _usersWithDevices = List<Map<String, dynamic>>.from(data['data']);
        } else {
          _usersWithDevices = [];
        }

        debugPrint('✅ Users loaded: ${_usersWithDevices.length} users');
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      _usersWithDevices = [];
    }
  }

  // ✅ جلب أجهزة مستخدم معين (جديد)
  Future<void> loadUserDevices(String userId) async {
    try {
      final dio = DioClient.instance;
      debugPrint('📡 Fetching devices for user: $userId');

      final response = await dio.get('/api/admin/users/$userId/devices');

      if (response.statusCode == 200) {
        final devicesData = response.data;
        List<Map<String, dynamic>> devices = [];

        if (devicesData is List) {
          devices = List<Map<String, dynamic>>.from(devicesData);
        } else if (devicesData['data'] is List) {
          devices = List<Map<String, dynamic>>.from(devicesData['data']);
        } else if (devicesData['devices'] is List) {
          devices = List<Map<String, dynamic>>.from(devicesData['devices']);
        }

        _currentUserDevices = devices;
        notifyListeners();
        debugPrint('✅ User $userId has ${devices.length} devices');
      }
    } catch (e) {
      debugPrint('❌ Error loading devices for user $userId: $e');
      _currentUserDevices = [];
      _error = e.toString();
      notifyListeners();
    }
  }

  // جلب أجهزة كل مستخدم على حدة
  Future<void> _loadDevicesForAllUsers() async {
    final dio = DioClient.instance;

    for (int i = 0; i < _usersWithDevices.length; i++) {
      final userId = _usersWithDevices[i]['id'];
      if (userId != null) {
        try {
          debugPrint('📡 Fetching devices for user: $userId');
          final response = await dio.get('/api/admin/users/$userId/devices');

          if (response.statusCode == 200) {
            final devicesData = response.data;
            List<Map<String, dynamic>> devices = [];

            if (devicesData is List) {
              devices = List<Map<String, dynamic>>.from(devicesData);
            } else if (devicesData['data'] is List) {
              devices = List<Map<String, dynamic>>.from(devicesData['data']);
            } else if (devicesData['devices'] is List) {
              devices = List<Map<String, dynamic>>.from(devicesData['devices']);
            }

            _usersWithDevices[i]['devices'] = devices;
            debugPrint('✅ User $userId has ${devices.length} devices');
          }
        } catch (e) {
          debugPrint('❌ Error loading devices for user $userId: $e');
          _usersWithDevices[i]['devices'] = [];
        }
      }
    }
  }

  // ✅ الموافقة على جهاز - مع تحويل id إلى String
  Future<bool> approveDevice(dynamic deviceId) async {
    // ✅ تحويل deviceId إلى String بأمان
    final String id = deviceId.toString();

    _approvingDeviceId = id;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      debugPrint('📡 Approving device: $id');

      final response = await dio.put('/api/admin/devices/$id/approve');

      debugPrint('📡 Approve response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _updateDeviceStatus(id, 'is_approved', true);
        _error = null;
        return true;
      }
      _error = 'فشل الموافقة على الجهاز';
      return false;
    } catch (e) {
      debugPrint('❌ Approve error: $e');
      _error = e.toString();
      return false;
    } finally {
      _approvingDeviceId = null;
      notifyListeners();
    }
  }

  // ✅ حظر جهاز - مع تحويل id إلى String
  Future<bool> blockDevice(dynamic deviceId) async {
    final String id = deviceId.toString();

    try {
      final dio = DioClient.instance;
      debugPrint('📡 Blocking device: $id');

      final response = await dio.put('/api/admin/devices/$id/block');

      debugPrint('📡 Block response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _updateDeviceStatus(id, 'is_blocked', true);
        _error = null;
        return true;
      }
      _error = 'فشل حظر الجهاز';
      return false;
    } catch (e) {
      debugPrint('❌ Block error: $e');
      _error = e.toString();
      return false;
    }
  }

  // ✅ حذف جهاز - مع تحويل id إلى String
  Future<bool> deleteDevice(dynamic deviceId) async {
    final String id = deviceId.toString();

    try {
      final dio = DioClient.instance;
      debugPrint('📡 Deleting device: $id');

      final response = await dio.delete('/api/admin/devices/$id');

      debugPrint('📡 Delete response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _removeDeviceFromLists(id);
        _error = null;
        return true;
      }
      _error = 'فشل حذف الجهاز';
      return false;
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      _error = e.toString();
      return false;
    }
  }

  // تحديث حالة جهاز في جميع القوائم
  void _updateDeviceStatus(String deviceId, String key, bool value) {
    // تحديث في _allDevices
    final deviceIndex =
        _allDevices.indexWhere((d) => d['id'].toString() == deviceId);
    if (deviceIndex != -1) {
      _allDevices[deviceIndex][key] = value;
    }

    // تحديث في _usersWithDevices
    for (final user in _usersWithDevices) {
      final userDevices = user['devices'] as List?;
      if (userDevices != null) {
        final index =
            userDevices.indexWhere((d) => d['id'].toString() == deviceId);
        if (index != -1) {
          userDevices[index][key] = value;
        }
      }
    }

    // ✅ تحديث في _currentUserDevices
    final currentIndex =
        _currentUserDevices.indexWhere((d) => d['id'].toString() == deviceId);
    if (currentIndex != -1) {
      _currentUserDevices[currentIndex][key] = value;
    }

    notifyListeners();
  }

  // إزالة جهاز من جميع القوائم
  void _removeDeviceFromLists(String deviceId) {
    // إزالة من _allDevices
    _allDevices.removeWhere((d) => d['id'].toString() == deviceId);

    // إزالة من _usersWithDevices
    for (final user in _usersWithDevices) {
      final userDevices = user['devices'] as List?;
      if (userDevices != null) {
        userDevices.removeWhere((d) => d['id'].toString() == deviceId);
      }
    }

    // ✅ إزالة من _currentUserDevices
    _currentUserDevices.removeWhere((d) => d['id'].toString() == deviceId);

    notifyListeners();
  }

  // إعادة ضبط جميع أجهزة المستخدم
  Future<bool> resetAllDevices(dynamic userId) async {
    final String id = userId.toString();

    try {
      final dio = DioClient.instance;
      final response =
          await dio.post('/api/admin/devices/users/$id/reset-devices');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _allDevices.removeWhere((d) => d['user_id'].toString() == id);

        final userIndex =
            _usersWithDevices.indexWhere((u) => u['id'].toString() == id);
        if (userIndex != -1) {
          _usersWithDevices[userIndex]['devices'] = [];
        }

        // ✅ مسح أجهزة المستخدم الحالي
        _currentUserDevices = [];

        notifyListeners();
        _error = null;
        return true;
      }
      _error = 'فشل إعادة ضبط الأجهزة';
      return false;
    } catch (e) {
      debugPrint('❌ Reset devices error: $e');
      _error = e.toString();
      return false;
    }
  }

  // الحصول على المستخدم المرتبط بجهاز معين
  Map<String, dynamic>? getUserForDevice(Map<String, dynamic> device) {
    final userId = device['user_id'] ?? device['userId'];
    if (userId == null) return null;

    try {
      return _usersWithDevices
          .firstWhere((user) => user['id'].toString() == userId.toString());
    } catch (e) {
      return null;
    }
  }

  // تحديث جميع البيانات
  Future<void> refreshAll() async {
    await loadAllData();
  }

  // ✅ مسح أجهزة المستخدم الحالي
  void clearCurrentUserDevices() {
    _currentUserDevices = [];
    notifyListeners();
  }
}
