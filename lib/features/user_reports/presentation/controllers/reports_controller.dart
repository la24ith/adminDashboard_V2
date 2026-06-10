import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class ReportsController extends ChangeNotifier {
  // بيانات التقارير
  Map<String, dynamic> _commitmentsData = {};
  Map<String, dynamic> _weightsData = {};
  Map<String, dynamic> _idealWeightsData = {};
  Map<String, dynamic> _expiredSubsData = {};
  List<Map<String, dynamic>> _usersList = [];

  // ✅ إحصائيات محسوبة من البيانات
  int _totalUsers = 0;
  double _avgCommitment = 0.0;
  int _achievedGoal = 0;
  int _expiredSubscriptions = 0;

  // حالات التحميل
  bool _isLoadingCommitments = false;
  bool _isLoadingWeights = false;
  bool _isLoadingIdealWeights = false;
  bool _isLoadingExpiredSubs = false;
  bool _isLoadingUsers = false;

  // حالات التصدير
  bool _isExportingPDF = false;
  bool _isExportingExcel = false;

  String? _error;
  String? _lastExportedPath;

  // Getters
  Map<String, dynamic> get commitmentsData => _commitmentsData;
  Map<String, dynamic> get weightsData => _weightsData;
  Map<String, dynamic> get idealWeightsData => _idealWeightsData;
  Map<String, dynamic> get expiredSubsData => _expiredSubsData;
  List<Map<String, dynamic>> get usersList => _usersList;

  int get totalUsers => _totalUsers;
  double get avgCommitment => _avgCommitment;
  int get achievedGoal => _achievedGoal;
  int get expiredSubscriptions => _expiredSubscriptions;

  bool get isLoadingCommitments => _isLoadingCommitments;
  bool get isLoadingWeights => _isLoadingWeights;
  bool get isLoadingIdealWeights => _isLoadingIdealWeights;
  bool get isLoadingExpiredSubs => _isLoadingExpiredSubs;
  bool get isLoadingUsers => _isLoadingUsers;

  bool get isExportingPDF => _isExportingPDF;
  bool get isExportingExcel => _isExportingExcel;
  bool get isExporting => _isExportingPDF || _isExportingExcel;

  String? get error => _error;
  String? get lastExportedPath => _lastExportedPath;

  ReportsController() {
    loadAllReports();
  }

  // ✅ فتح ملف مصدر
  Future<bool> openExportedFile({
    required String fileName,
    required List<int> fileBytes,
    String? fileExtension,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final fullFileName =
          fileExtension != null ? '$fileName.$fileExtension' : fileName;
      final filePath = '${directory.path}/$fullFileName';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      debugPrint('📁 File saved at: $filePath');

      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        debugPrint('✅ File opened successfully: $fullFileName');
        return true;
      } else {
        debugPrint('⚠️ Could not open file: ${result.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error opening file: $e');
      return false;
    }
  }

  // ✅ حفظ الملف
  Future<String> _saveFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ✅ تصدير PDF
  Future<String?> exportPDF() async {
    _isExportingPDF = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get<List<int>>(
        ApiConstants.adminReportsExportPdf,
        options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept-Language': "ar"}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('فشل تصدير PDF');
      }

      final bytes = Uint8List.fromList(response.data!);
      final fileName =
          'users_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final path = await _saveFile(bytes: bytes, fileName: fileName);

      _lastExportedPath = path;
      return path;
    } catch (e) {
      debugPrint('❌ PDF Export error: $e');
      return null;
    } finally {
      _isExportingPDF = false;
      notifyListeners();
    }
  }

  // ✅ تصدير Excel
  Future<String?> exportExcel() async {
    _isExportingExcel = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get<List<int>>(
        ApiConstants.adminReportsExportExcel,
        options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept-Language': "ar"}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('فشل تصدير Excel');
      }

      final bytes = Uint8List.fromList(response.data!);
      final fileName =
          'users_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final path = await _saveFile(bytes: bytes, fileName: fileName);

      _lastExportedPath = path;
      return path;
    } catch (e) {
      debugPrint('❌ Excel Export error: $e');
      return null;
    } finally {
      _isExportingExcel = false;
      notifyListeners();
    }
  }

  // ==================== تحميل التقارير من API ====================

  Future<void> loadAllReports() async {
    loadCommitmentsReport();
    loadIdealWeightsReport();
    loadExpiredSubsReport();
    loadUsersList();
  }

  // 📊 57 - تقرير الالتزامات (Reports commitments)
  Future<void> loadCommitmentsReport() async {
    _isLoadingCommitments = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminReportsCommitments);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ معالجة هيكل Pagination
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;

          if (dataList.isNotEmpty) {
            // ✅ أخذ أول عنصر فقط (لأن التقرير يعيد مصفوفة)
            final firstItem = dataList.first as Map<String, dynamic>;
            _commitmentsData = firstItem;

            // ✅ استخراج القيم من العنصر الأول مباشرة
            _totalUsers = firstItem['total_users'] ?? 0;
            _avgCommitment = (firstItem['avg_commitment'] ?? 0.0).toDouble();
            _achievedGoal = firstItem['achieved_goal'] ?? 0;
          } else {
            // ✅ البيانات فارغة
            _commitmentsData = {};
            _totalUsers = 0;
            _avgCommitment = 0.0;
            _achievedGoal = 0;
          }
        } else {
          // ✅ استجابة بدون هيكل pagination
          _commitmentsData = responseData;
          _totalUsers = responseData['total_users'] ?? 0;
          _avgCommitment = (responseData['avg_commitment'] ?? 0.0).toDouble();
          _achievedGoal = responseData['achieved_goal'] ?? 0;
        }
      } else {
        throw Exception('فشل تحميل تقرير الالتزام');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Commitments error: $e');
      _commitmentsData = {};
      _totalUsers = 0;
      _avgCommitment = 0.0;
      _achievedGoal = 0;
    } finally {
      _isLoadingCommitments = false;
      notifyListeners();
    }
  }

  // ⚖️ 58 - تقرير الأوزان (مع زيادة Timeout)
  Future<void> loadWeightsReport() async {
    _isLoadingWeights = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        ApiConstants.adminReportsWeights,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          _weightsData = dataList.isNotEmpty ? dataList.first : {};
        } else {
          _weightsData = responseData;
        }
      } else {
        throw Exception('فشل تحميل تقرير الأوزان');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Weights error: $e');
      _weightsData = {};
    } finally {
      _isLoadingWeights = false;
      notifyListeners();
    }
  }

  // 🏆 59 - تقرير الوزن المثالي
  Future<void> loadIdealWeightsReport() async {
    _isLoadingIdealWeights = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminReportsIdealWeights);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ معالجة هيكل Pagination
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          _idealWeightsData = {
            'users': dataList,
            'total': dataList.length,
          };
        } else if (responseData.containsKey('users')) {
          _idealWeightsData = responseData;
        } else {
          _idealWeightsData = {'users': [], 'total': 0};
        }
      } else {
        throw Exception('فشل تحميل تقرير الوزن المثالي');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Ideal weights error: $e');
      _idealWeightsData = {'users': [], 'total': 0};
    } finally {
      _isLoadingIdealWeights = false;
      notifyListeners();
    }
  }

  // ⏰ 60 - تقرير الاشتراكات المنتهية
  Future<void> loadExpiredSubsReport() async {
    _isLoadingExpiredSubs = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminReportsExpiredSubs);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ معالجة هيكل Pagination
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          _expiredSubsData = {
            'users': dataList,
            'total': dataList.length,
          };
          _expiredSubscriptions = dataList.length;
        } else if (responseData.containsKey('users')) {
          _expiredSubsData = responseData;
          _expiredSubscriptions = (responseData['users'] as List?)?.length ?? 0;
        } else {
          _expiredSubsData = {'users': [], 'total': 0};
          _expiredSubscriptions = 0;
        }
      } else {
        throw Exception('فشل تحميل تقرير الاشتراكات المنتهية');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Expired subs error: $e');
      _expiredSubsData = {'users': [], 'total': 0};
      _expiredSubscriptions = 0;
    } finally {
      _isLoadingExpiredSubs = false;
      notifyListeners();
    }
  }

  // 👥 تحميل قائمة المستخدمين (مع زيادة Timeout)
  Future<void> loadUsersList() async {
    _isLoadingUsers = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.adminUsers}?per_page=100',
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData.containsKey('data')) {
          _usersList = List<Map<String, dynamic>>.from(responseData['data']);
        } else if (responseData is List) {
          _usersList = List<Map<String, dynamic>>.from(responseData);
        } else {
          _usersList = [];
        }

        // ✅ تحديث إجمالي المستخدمين إذا لم يتم تعيينه من قبل
        if (_totalUsers == 0 && _usersList.isNotEmpty) {
          _totalUsers = _usersList.length;
          notifyListeners();
        }
      } else {
        throw Exception('فشل تحميل قائمة المستخدمين');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Users list error: $e');
      _usersList = [];
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadCommitmentsReport(),
      loadIdealWeightsReport(),
      loadExpiredSubsReport(),
      loadUsersList(),
    ]);
  }
}
