// data/datasources/user_local_datasource.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_subscription_entity.dart';
import '../../domain/repositories/user_repository.dart';

class UserLocalDataSource {
  static const String _cachedSubscriptionsKey = 'cached_subscriptions';
  static const String _cachedTimestampKey = 'cached_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 5);

  final SharedPreferences _prefs;

  UserLocalDataSource(this._prefs);

  // 💾 حفظ الـ Subscriptions في الـ Cache
  Future<void> cacheSubscriptions(
      PaginatedUserSubscriptions subscriptions) async {
    try {
      final data = subscriptions.data.map((entity) {
        return entity.toJson();
      }).toList();

      final cacheData = {
        'currentPage': subscriptions.currentPage,
        'data': data,
        'lastPage': subscriptions.lastPage,
        'total': subscriptions.total,
        'perPage': subscriptions.perPage,
        'hasMore': subscriptions.hasMore,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_cachedSubscriptionsKey, jsonEncode(cacheData));
      await _prefs.setString(
          _cachedTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('⚠️ Error caching subscriptions: $e');
    }
  }

  // 📥 استرجاع الـ Subscriptions من الـ Cache
  Future<PaginatedUserSubscriptions?> getCachedSubscriptions() async {
    try {
      // التحقق من صلاحية الـ Cache
      final timestampStr = _prefs.getString(_cachedTimestampKey);
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) > _cacheDuration) {
          return null;
        }
      }

      final dataStr = _prefs.getString(_cachedSubscriptionsKey);
      if (dataStr == null) return null;

      final data = jsonDecode(dataStr) as Map<String, dynamic>;

      final entities = (data['data'] as List).map((item) {
        return UserSubscriptionEntity.fromJson(item as Map<String, dynamic>);
      }).toList();

      return PaginatedUserSubscriptions(
        currentPage: data['currentPage'] ?? 1,
        data: entities,
        lastPage: data['lastPage'] ?? 1,
        total: data['total'] ?? 0,
        perPage: data['perPage'] ?? 20,
        hasMore: data['hasMore'] ?? false,
      );
    } catch (e) {
      print('⚠️ Error reading cache: $e');
      return null;
    }
  }

  // 🗑️ مسح الـ Cache
  Future<void> clearCache() async {
    await _prefs.remove(_cachedSubscriptionsKey);
    await _prefs.remove(_cachedTimestampKey);
  }
}
