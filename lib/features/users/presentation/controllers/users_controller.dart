// presentation/controllers/users_controller.dart

import 'package:admin_dashboard/features/users/domain/usecases/add_user.dart';
import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user_subscription_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/usecases/get_subscriptions.dart';
import '../../domain/usecases/update_user.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/extend_subscription.dart';
import '../../domain/usecases/update_subscription.dart';
import '../../domain/usecases/toggle_user_status.dart';
import '../../domain/usecases/toggle_multi_device.dart';
import '../../domain/repositories/user_repository.dart';

class UsersController extends ChangeNotifier {
  // ✅ Use Cases
  final GetSubscriptions getSubscriptionsUseCase;
  final CreateUser createUserUseCase;
  final UpdateUser updateUserUseCase;
  final DeleteUser deleteUserUseCase;
  final ExtendSubscription extendSubscriptionUseCase;
  final UpdateSubscription updateSubscriptionUseCase;
  final ToggleUserStatus toggleUserStatusUseCase;
  final ToggleMultiDevice toggleMultiDeviceUseCase;

  // ✅ State
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _isActionInProgress = false;
  bool _isDeleting = false;
  String? _deletingUserId;
  String? _error;
  String? _successMessage;

  // ✅ Pagination State
  int _currentPage = 1;
  int _perPage = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _searchQuery;
  String? _filterStatus;

  // ✅ Getters
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  bool get isDeleting => _isDeleting;
  String? get deletingUserId => _deletingUserId;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get currentPage => _currentPage;

  UsersController({
    required this.getSubscriptionsUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.extendSubscriptionUseCase,
    required this.updateSubscriptionUseCase,
    required this.toggleUserStatusUseCase,
    required this.toggleMultiDeviceUseCase,
  }) {
    loadUsers();
  }

  // ✅ 📥 تحميل المستخدمين (الصفحة الأولى أو التحديث)
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _users.clear();
    }

    _isLoading = refresh || _users.isEmpty;
    _error = null;
    notifyListeners();

    final result = await getSubscriptionsUseCase(
      page: _currentPage,
      perPage: _perPage,
      search: _searchQuery,
      status: _filterStatus,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (paginated) {
        final newUsers = paginated.data.map((entity) {
          return entity.toUiMap();
        }).toList();

        if (_currentPage == 1) {
          _users = newUsers;
        } else {
          _users.addAll(newUsers);
        }

        _currentPage = paginated.currentPage + 1;
        _hasMore = paginated.hasMore;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ✅ 📥 تحميل المزيد (Pagination)
  Future<void> loadMoreUsers() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await getSubscriptionsUseCase(
      page: _currentPage,
      perPage: _perPage,
      search: _searchQuery,
      status: _filterStatus,
    );

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoadingMore = false;
        notifyListeners();
      },
      (paginated) {
        final newUsers = paginated.data.map((entity) {
          return entity.toUiMap();
        }).toList();

        _users.addAll(newUsers);
        _currentPage = paginated.currentPage + 1;
        _hasMore = paginated.hasMore;
        _isLoadingMore = false;
        notifyListeners();
      },
    );
  }

  // ✅ 🔍 البحث عن المستخدمين
  Future<void> searchUsers(String query) async {
    _searchQuery = query.trim().isEmpty ? null : query.trim();
    _currentPage = 1;
    _hasMore = true;
    await loadUsers(refresh: true);
  }

  // ✅ 🏷️ فلترة المستخدمين
  Future<void> filterUsers(String? status) async {
    _filterStatus = (status == 'all' || status == null) ? null : status;
    _currentPage = 1;
    _hasMore = true;
    await loadUsers(refresh: true);
  }

  // ✅ ✨ إنشاء مستخدم جديد
  Future<bool> createUser(Map<String, dynamic> userData) async {
    _startAction();

    final result = await createUserUseCase(userData);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage = 'تم إنشاء المستخدم بنجاح';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ ✏️ تحديث مستخدم
  Future<bool> updateUser(String userId, Map<String, dynamic> userData) async {
    _startAction();

    final result = await updateUserUseCase(int.parse(userId), userData);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage = 'تم تحديث المستخدم بنجاح';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ 🗑️ حذف مستخدم
  Future<bool> deleteUser(String userId) async {
    _isDeleting = true;
    _deletingUserId = userId;
    notifyListeners();

    final result = await deleteUserUseCase(int.parse(userId));

    return result.fold(
      (failure) {
        _error = failure.message;
        _isDeleting = false;
        _deletingUserId = null;
        notifyListeners();
        return false;
      },
      (_) {
        _users.removeWhere((u) => u['id'].toString() == userId);
        _successMessage = 'تم حذف المستخدم بنجاح';
        _isDeleting = false;
        _deletingUserId = null;
        notifyListeners();
        return true;
      },
    );
  }

  // ✅ ⏰ تمديد الاشتراك
  Future<bool> extendSubscription(String userId, int days) async {
    _startAction();

    final result = await extendSubscriptionUseCase(int.parse(userId), days);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage = 'تم تمديد الاشتراك بنجاح (+$days يوماً)';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ 📝 تحديث الاشتراك
  Future<bool> updateSubscription(
      String userId, Map<String, dynamic> data) async {
    _startAction();

    final result = await updateSubscriptionUseCase(int.parse(userId), data);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage = 'تم تحديث الاشتراك بنجاح';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ 🔄 تبديل حالة المستخدم
  Future<bool> toggleUserStatus(String userId, bool currentStatus) async {
    _startAction();

    final result =
        await toggleUserStatusUseCase(int.parse(userId), currentStatus);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage =
            currentStatus ? 'تم تعليق المستخدم' : 'تم تفعيل المستخدم';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ 🔄 تبديل وضع الأجهزة المتعددة
  Future<bool> toggleMultiDevice(String userId, bool currentStatus) async {
    _startAction();

    final result =
        await toggleMultiDeviceUseCase(int.parse(userId), currentStatus);

    return result.fold(
      (failure) {
        _error = failure.message;
        _finishAction();
        return false;
      },
      (_) {
        _successMessage = currentStatus
            ? 'تم تعطيل الأجهزة المتعددة'
            : 'تم تفعيل الأجهزة المتعددة';
        loadUsers(refresh: true);
        _finishAction();
        return true;
      },
    );
  }

  // ✅ 🔄 تحديث بيانات مستخدم واحد
  Future<void> refreshUserData(String userId) async {
    await loadUsers(refresh: true);
  }

  // ✅ 🛠️ Helper methods
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

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // ✅ 🗑️ مسح الـ Cache
  Future<void> clearCache() async {
    // يمكن إضافة دالة في الـ Repository
    // await localDataSource.clearCache();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
