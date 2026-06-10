import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/ad_model.dart'; // تأكد من إضافة هذا السطر

class AdsController extends ChangeNotifier {
  List<AdModel> _ads = []; // تغيير من Map إلى AdModel
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _error;
  String? _successMessage;

  List<AdModel> get ads => _ads; // تغيير نوع الإرجاع
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;
  String? get successMessage => _successMessage;

  AdsController() {
    loadAds();
  }

  Future<void> loadAds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminAds);

      if (response.statusCode == 200) {
        final allAds = response.data['data'] ?? response.data;

        // تحويل البيانات إلى AdModel
        final List<AdModel> adModels = [];
        final seenIds = <int>{};

        for (var ad in allAds) {
          final id = ad['id'] as int;
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            adModels.add(AdModel.fromJson(ad));
          }
        }

        _ads = adModels;
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('فشل تحميل الإعلانات');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAd(Map<String, dynamic> adData, File imageFile) async {
    if (_isActionInProgress) return false;
    final dio = DioClient.instance;
    final formData = FormData();
    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      adData.forEach((key, value) {
        if (value != null) {
          formData.fields.add(
            MapEntry(key, value.toString()),
          );
        }
      });

      if (imageFile != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ),
        );
      }

      final response = await DioClient.instance.post(
        ApiConstants.adminAds,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newAd = response.data['data'] ?? response.data;
        final newAdModel = AdModel.fromJson(newAd);

        // التحقق من عدم وجود الإعلان مسبقاً
        final exists = _ads.any((ad) => ad.id == newAdModel.id);
        if (!exists) {
          _ads.insert(0, newAdModel);
        }

        _successMessage = 'تم إضافة الإعلان بنجاح';
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل إنشاء الإعلان');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAd(String adId, Map<String, dynamic> adData) async {
    if (_isActionInProgress) return false;

    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.put(
        '${ApiConstants.adminAds}/$adId',
        data: adData,
      );

      if (response.statusCode == 200) {
        final updatedAd = response.data['data'] ?? response.data;
        final updatedAdModel = AdModel.fromJson(updatedAd);

        final index = _ads.indexWhere((ad) => ad.id.toString() == adId);
        if (index != -1) {
          _ads[index] = updatedAdModel;
        }

        _successMessage = 'تم تحديث الإعلان بنجاح';
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل تحديث الإعلان');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAd(String adId) async {
    if (_isActionInProgress) return false;

    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.delete('${ApiConstants.adminAds}/$adId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _ads.removeWhere((ad) => ad.id.toString() == adId);

        _successMessage = 'تم حذف الإعلان بنجاح';
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل حذف الإعلان');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAd(String adId, bool isActive) async {
    if (_isActionInProgress) return false;

    _isActionInProgress = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final endpoint = ApiConstants.adminAdsToggle.replaceAll('{ad_id}', adId);
      final response = await dio.put(endpoint, data: {
        'is_active': !isActive,
      });

      if (response.statusCode == 200) {
        final index = _ads.indexWhere((ad) => ad.id.toString() == adId);
        if (index != -1) {
          _ads[index] = _ads[index].copyWith(isActive: !isActive);
        }

        _successMessage = !isActive ? 'تم تفعيل الإعلان' : 'تم تعطيل الإعلان';
        _isActionInProgress = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('فشل تغيير حالة الإعلان');
      }
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> recordClick(String adId) async {
    try {
      final dio = DioClient.instance;
      final endpoint = ApiConstants.adminAdsClick.replaceAll('{ad_id}', adId);
      await dio.post(endpoint);
    } catch (e) {
      print('Error recording click: $e');
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
