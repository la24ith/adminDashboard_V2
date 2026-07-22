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
  bool _isLoadingDashboardStats = false;

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
  bool get isLoadingDashboardStats => _isLoadingDashboardStats;

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

  // ✅ يفحص أول بايتات الملف ليحدد نوعه الحقيقي (بغض النظر عمّا يدّعيه السيرفر)
  // ZIP/XLSX الحقيقي يبدأ بـ PK (0x50, 0x4B)، أي شيء غير ذلك نعتبره نص/CSV
  bool _isRealZipXlsx(Uint8List bytes) {
    return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
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
  // ⚠️ ملاحظة: الـ API حاليًا بيرجّع CSV خام مو ملف xlsx حقيقي (تم اكتشافه عبر فحص البايتات).
  // لحد ما ينصلح الباك اند (لازم يستخدم Excel::XLSX writer type بدل Excel::CSV)،
  // منحفظ الملف بامتداد يطابق محتواه الفعلي حتى يشتغل صح بالمشاركة والفتح.
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

      // ✅ تحديد الامتداد الصحيح بناءً على المحتوى الفعلي وليس افتراضًا
      final isRealXlsx = _isRealZipXlsx(bytes);
      final extension = isRealXlsx ? 'xlsx' : 'csv';

      if (!isRealXlsx) {
        debugPrint(
            '⚠️ تنبيه: الـ API رجّع CSV خام بدل xlsx حقيقي — يُنصح بإصلاح الباك اند (Excel::XLSX writer type)');
      }

      final fileName =
          'users_report_${DateTime.now().millisecondsSinceEpoch}.$extension';
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
    _loadDashboardStats();
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
        // ملاحظة: لم نعد نستخرج total_users/avg_commitment/achieved_goal من هنا،
        // لأن هذا الـ endpoint مُقسَّم لصفحات (paginated) وأول عنصر فيه لا يمثل
        // الإجمالي الحقيقي لكل المستخدمين. الأرقام الإجمالية تُجلب الآن حصرياً
        // من نفس endpoint الداشبورد عبر _loadDashboardStats() لضمان التطابق.
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          _commitmentsData =
              dataList.isNotEmpty ? dataList.first as Map<String, dynamic> : {};
        } else {
          _commitmentsData = responseData;
        }
      } else {
        throw Exception('فشل تحميل تقرير الالتزام');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Commitments error: $e');
      _commitmentsData = {};
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
        // ملاحظة: استخدمنا responseData['total'] (حقل Laravel القياسي للعدد
        // الإجمالي عبر كل الصفحات) بدل dataList.length التي كانت تُرجع فقط
        // عدد عناصر الصفحة الحالية (مثلاً 15) حتى لو كان الإجمالي الحقيقي أكبر.
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          final total = _toNum(responseData['total'] ?? dataList.length).toInt();
          _idealWeightsData = {
            'users': dataList,
            'total': total,
          };
          _achievedGoal = total;
        } else if (responseData.containsKey('users')) {
          final usersList = responseData['users'] as List?;
          final total = _toNum(responseData['total'] ?? usersList?.length ?? 0).toInt();
          _idealWeightsData = {
            'users': usersList ?? [],
            'total': total,
          };
          _achievedGoal = total;
        } else {
          _idealWeightsData = {'users': [], 'total': 0};
          _achievedGoal = 0;
        }
      } else {
        throw Exception('فشل تحميل تقرير الوزن المثالي');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Ideal weights error: $e');
      _idealWeightsData = {'users': [], 'total': 0};
      _achievedGoal = 0;
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
        // ملاحظة: 'total' هنا يُستخدم فقط لعرض "+ N مستخدمين آخرين" أسفل القائمة.
        // رقم بطاقة "اشتراكات منتهية" (KPI) لم يعد يُشتق من هنا؛ يأتي حصرياً
        // من نفس endpoint الداشبورد عبر _loadDashboardStats() لضمان التطابق.
        if (responseData.containsKey('data')) {
          final dataList = responseData['data'] as List;
          final total = _toNum(responseData['total'] ?? dataList.length).toInt();
          _expiredSubsData = {
            'users': dataList,
            'total': total,
          };
        } else if (responseData.containsKey('users')) {
          final usersList = responseData['users'] as List?;
          final total = _toNum(responseData['total'] ?? usersList?.length ?? 0).toInt();
          _expiredSubsData = {
            'users': usersList ?? [],
            'total': total,
          };
        } else {
          _expiredSubsData = {'users': [], 'total': 0};
        }
      } else {
        throw Exception('فشل تحميل تقرير الاشتراكات المنتهية');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Expired subs error: $e');
      _expiredSubsData = {'users': [], 'total': 0};
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
      _loadDashboardStats(),
    ]);
  }

  /// ✅ تحويل آمن لأي قيمة قادمة من الـ API (num أو String أو null)
  num _toNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  /// ✅ جلب الإحصائيات الإجمالية من نفس endpoint الداشبورد (وليس من تقرير
  /// الالتزامات المُقسَّم إلى صفحات). هذا يضمن أن أرقام "إجمالي المستخدمين"،
  /// "معدل الالتزام"، و"اشتراكات منتهية" في صفحة التقارير تُطابق دائماً
  /// نفس الأرقام الظاهرة في الداشبورد الرئيسي، لأنها تأتي من نفس المصدر تماماً.
  Future<void> _loadDashboardStats() async {
    _isLoadingDashboardStats = true;
    notifyListeners();

    try {
      final dio = DioClient.instance;
      final response = await dio.get(ApiConstants.adminDashboard);

      if (response.statusCode == 200) {
        final stats = response.data['stats'] ?? response.data;
        _totalUsers = _toNum(stats['total_users']).toInt();
        _avgCommitment = _toNum(stats['commitment_rate']).toDouble();
        _expiredSubscriptions = _toNum(stats['expired_subscriptions']).toInt();
      }
    } catch (e) {
      debugPrint('❌ Dashboard stats error (reports page): $e');
      // ✅ نُبقي القيم القديمة (fallback) بدل ترك الشاشة فارغة أو صفر فجأة
    } finally {
      _isLoadingDashboardStats = false;
      notifyListeners();
    }
  }
}
