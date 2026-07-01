import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class PostsController extends ChangeNotifier {
  // Posts data
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _postsPerPage = 20;
  bool _hasContext = false;
  BuildContext? _context;

  // Actions state
  bool _isActionInProgress = false;
  String? _error;
  String? _successMessage;

  void setContext(BuildContext context) {
    _context = context;
    _hasContext = true;
  }

  // دالة مساعدة للتحقق من وجود Context
  bool get hasValidContext => _hasContext && _context != null;

  // دالة مساعدة لعرض SnackBar بأمان
  void _showSnackBar(String message, {bool isError = false}) {
    if (_hasContext && _context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Repository
  final PostRepository _repository = PostRepository();

  // Media upload tracking
  final Map<String, bool> _uploadingMedia = {};
  final Map<String, double> _uploadProgressMap = {};

  // Per-post details loading tracking (used by UI e.g. PostCard tap)
  final Map<int, bool> _loadingDetails = {};

  // ==================== LIFECYCLE SAFETY ====================
  bool _isDisposed = false;

  // Safe notifyListeners - prevents calls after dispose and during build
  void _safeNotify() {
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ==================== GETTERS ====================

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isActionInProgress => _isActionInProgress;
  String? get error => _error;
  String? get successMessage => _successMessage;

  bool isUploadingMedia(String key) => _uploadingMedia[key] ?? false;
  double getUploadProgress(String key) => _uploadProgressMap[key] ?? 0.0;

  /// هل يتم حالياً جلب تفاصيل المنشور صاحب هذا المعرف (يُستخدم لإظهار مؤشر تحميل على الكرت)
  bool isLoadingPostDetails(int postId) => _loadingDetails[postId] ?? false;

  PostsController();

  Future<void> init() async {
    await loadPosts();
  }

  // ==================== POSTS CRUD WITH PAGINATION ====================

  Future<void> loadPosts({bool forceRefresh = false}) async {
    if (_isLoading || _isDisposed) return;

    if (forceRefresh) {
      _resetPagination();
    }

    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        perPage: _postsPerPage,
        forceRefresh: forceRefresh,
      );

      if (_isDisposed) return;

      if (forceRefresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length == _postsPerPage;
      _error = null;
    } catch (e) {
      if (_isDisposed) return;
      _error = _getErrorMessage(e);
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _isLoading || _isDisposed) return;

    _isLoadingMore = true;
    _currentPage++;
    _safeNotify();

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        perPage: _postsPerPage,
      );

      if (_isDisposed) return;

      if (newPosts.isNotEmpty) {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length == _postsPerPage;
      _error = null;
    } catch (e) {
      if (_isDisposed) return;
      _error = _getErrorMessage(e);
      _hasMore = false;
    } finally {
      if (!_isDisposed) {
        _isLoadingMore = false;
        _safeNotify();
      }
    }
  }

  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _posts.clear();
  }

  /// جلب تفاصيل منشور واحد كاملة عبر GET {{base_url}}/api/admin/posts/{post_id}
  /// تُستخدم عند فتح صفحة تفاصيل المنشور (مثلاً عند الضغط على كرت المنشور)
  /// لضمان وصول كل بيانات الوسائط (فيديو/صوت/صور) حتى لو لم تكن متوفرة
  /// بالكامل في استجابة قائمة المنشورات.
  Future<Post> getPostDetails(int postId, {bool forceRefresh = true}) async {
    _loadingDetails[postId] = true;
    _safeNotify();

    try {
      final post = await _repository.getPostById(
        postId,
        forceRefresh: forceRefresh,
      );

      if (!_isDisposed) {
        // تحديث المنشور في القائمة المحلية إن وجد، حتى تكون البيانات متسقة
        _updatePostInList(post);
      }

      return post;
    } catch (e) {
      _error = _getErrorMessage(e);
      rethrow;
    } finally {
      _loadingDetails[postId] = false;
      _safeNotify();
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    required PostStatus status,
    required String segment,
    DateTime? scheduledFor,
    File? thumbnailFile,
    File? videoFile,
    File? audioFile,
    String? thumbnailUrl,
    String? videoUrl,
    String? audioUrl,
  }) async {
    if (_isActionInProgress || _isDisposed) return false;

    _setActionState(true, clearMessages: true);

    try {
      final dio = DioClient.instance;

      final postData = {
        'title': title,
        'content': content,
        'status': status.apiValue,
        'segment': segment,
        if (scheduledFor != null)
          'scheduled_for': scheduledFor.toIso8601String(),
      };

      final response = await dio.post(ApiConstants.adminPosts, data: postData);
      if (_isDisposed) return false;

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('فشل إنشاء المنشور');
      }

      final int postId = response.data['id'];

      try {
        await _uploadAllMedia(
          postId,
          thumbnailFile,
          thumbnailUrl,
          videoFile,
          videoUrl,
          audioFile,
          audioUrl,
        );
      } catch (mediaError) {
        // ❗ فشل رفع أحد الملحقات: لا نترك منشوراً منشوراً بدون وسائطه.
        // نحذف المنشور الذي أُنشئ للتو (rollback) حتى لا يظهر للمستخدمين
        // بشكل ناقص أو بدون الفيديو/الصورة/الصوت المطلوب.
        debugPrint(
            '⚠️ فشل رفع الوسائط، سيتم حذف المنشور الذي تم إنشاؤه (id=$postId): $mediaError');
        try {
          await dio.delete('${ApiConstants.adminPosts}/$postId');
          _repository.deletePostFromCache(postId);
        } catch (rollbackError) {
          debugPrint('⚠️ تعذر حذف المنشور بعد فشل رفع الوسائط: $rollbackError');
        }
        rethrow;
      }

      if (_isDisposed) return false;

      // ✅ إيقاف حالة الحفظ أولاً قبل تحميل المنشورات
      _successMessage = 'تم إنشاء المنشور بنجاح';
      _isActionInProgress = false;
      _safeNotify();

      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      _showSnackBar(_error!, isError: true);
      return false;
    } finally {
      // نضمن إعادة الحالة في حال وقع استثناء
      if (!_isDisposed && _isActionInProgress) {
        _isActionInProgress = false;
        _safeNotify();
      }
    }
  }

  Future<bool> updatePost(
    int postId, {
    String? title,
    String? content,
    PostStatus? status,
    String? segment,
    DateTime? scheduledFor,
    File? thumbnailFile,
    File? videoFile,
    File? audioFile,
    String? thumbnailUrl,
    String? videoUrl,
    String? audioUrl,
  }) async {
    if (_isActionInProgress || _isDisposed) return false;

    _setActionState(true, clearMessages: true);

    try {
      final dio = DioClient.instance;

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (status != null) updateData['status'] = status.apiValue;
      // ✅ إصلاح: segment مستقل عن status
      if (segment != null) updateData['segment'] = segment;
      if (scheduledFor != null)
        updateData['scheduled_for'] = scheduledFor.toIso8601String();

      if (updateData.isNotEmpty) {
        await dio.put('/api/admin/posts/$postId', data: updateData);
        if (_isDisposed) return false;
      }

      try {
        await _uploadAllMedia(
          postId,
          thumbnailFile,
          thumbnailUrl,
          videoFile,
          videoUrl,
          audioFile,
          audioUrl,
        );
      } catch (mediaError) {
        // ❗ فشل رفع أحد الملحقات أثناء التحديث: لا نعرض رسالة نجاح
        // ولا نعيد تحميل القائمة وكأن كل شيء تم بنجاح.
        debugPrint(
            '⚠️ فشل رفع الوسائط أثناء تحديث المنشور $postId: $mediaError');
        rethrow;
      }

      if (_isDisposed) return false;

      // ✅ إيقاف حالة الحفظ أولاً قبل تحميل المنشورات
      _successMessage = 'تم تحديث المنشور';
      _isActionInProgress = false;
      _safeNotify();

      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      _showSnackBar(_error!, isError: true);
      return false;
    } finally {
      // نضمن إعادة الحالة في حال وقع استثناء
      if (!_isDisposed && _isActionInProgress) {
        _isActionInProgress = false;
        _safeNotify();
      }
    }
  }

  Future<bool> deletePost(int postId) async {
    if (_isActionInProgress || _isDisposed) return false;
    _setActionState(true);

    try {
      final dio = DioClient.instance;
      final response = await dio.delete('/api/admin/posts/$postId');

      if (_isDisposed) return false;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _repository.deletePostFromCache(postId);
        _posts.removeWhere((post) => post.id == postId);
        _successMessage = 'تم حذف المنشور';
        _isActionInProgress = false; // ✅ أوقف الـ action قبل الـ notify
        _safeNotify(); // ✅ notify واحدة فقط
        return true;
      }
      throw Exception('فشل الحذف');
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      return false;
    } finally {
      // ✅ فقط إذا لم ينجح (لم يتم إيقافه في try)
      if (!_isDisposed && _isActionInProgress) {
        _isActionInProgress = false;
        _safeNotify();
      }
    }
  }

  Future<bool> schedulePost(int postId, DateTime scheduledDate) async {
    if (_isActionInProgress || _isDisposed) return false;
    _setActionState(true);

    try {
      final dio = DioClient.instance;
      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostSchedule, postId);
      final response = await dio.put(endpoint, data: {
        'scheduled_for': scheduledDate.toIso8601String(),
      });

      if (_isDisposed) return false;

      if (response.statusCode == 200) {
        _successMessage = 'تمت الجدولة بنجاح';
        _isActionInProgress = false;
        _safeNotify();

        _repository.clearCache();
        _resetPagination();
        await loadPosts(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      return false;
    } finally {
      if (!_isDisposed && _isActionInProgress) {
        _isActionInProgress = false;
        _safeNotify();
      }
    }
  }

  // ==================== MEDIA UPLOAD ====================

  Future<void> _uploadAllMedia(
    int postId,
    File? thumbnailFile,
    String? thumbnailUrl,
    File? videoFile,
    String? videoUrl,
    File? audioFile,
    String? audioUrl,
  ) async {
    // رفع الصورة المصغرة
    if (thumbnailFile != null && !_isDisposed) {
      await _uploadMedia(postId, thumbnailFile, 'thumbnail');
    } else if (thumbnailUrl != null &&
        thumbnailUrl.isNotEmpty &&
        !_isDisposed) {
      await _updatePostField(postId, 'thumbnail', thumbnailUrl);
    }

    // رفع الفيديو
    if (videoFile != null && !_isDisposed) {
      await _uploadMedia(postId, videoFile, 'video');
    } else if (videoUrl != null && videoUrl.isNotEmpty && !_isDisposed) {
      await _updatePostField(postId, 'video_url', videoUrl);
    }

    // رفع الصوت
    if (audioFile != null && !_isDisposed) {
      await _uploadMedia(postId, audioFile, 'audio');
    } else if (audioUrl != null && audioUrl.isNotEmpty && !_isDisposed) {
      await _updatePostField(postId, 'audio_url', audioUrl);
    }
  }

  // دالة تحديد MIME type بشكل صحيح للملفات
  String _getCorrectMimeType(File file, String type) {
    final filePath = file.path;
    final extension = filePath.split('.').last.toLowerCase();

    debugPrint(
        '🔍 Detecting MIME for: $filePath, type: $type, extension: $extension');

    if (type == 'audio') {
      if (extension == 'mp3') return 'audio/mpeg';
      if (extension == 'm4a') return 'audio/mp4';
      if (extension == 'aac') return 'audio/aac';
      if (extension == 'wav') return 'audio/wav';
      return 'audio/mpeg';
    }

    if (type == 'video') {
      if (extension == 'mp4') return 'video/mp4';
      if (extension == 'mov') return 'video/quicktime';
      return 'video/mp4';
    }

    if (type == 'image') {
      if (extension == 'png') return 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }

  // ✅ إصلاح: تحويل الصوت فقط (وليس جميع الملفات) مع التحقق من نجاح FFmpeg
  Future<File> _convertAudioFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'm4a') {
      try {
        final newPath = file.path.replaceAll('.m4a', '.mp3');
        final mp3File = File(newPath);

        final session = await FFmpegKit.execute(
          '-i ${file.path} -codec:a libmp3lame -qscale:a 2 ${mp3File.path}',
        );
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint('✅ Converted m4a to mp3: ${mp3File.path}');
          return mp3File;
        } else {
          debugPrint('⚠️ FFmpeg conversion failed, using original');
          return file;
        }
      } catch (e) {
        debugPrint('⚠️ Conversion failed, using original: $e');
        return file;
      }
    }
    return file;
  }

  Future<void> _uploadMedia(int postId, File file, String type) async {
    if (_isDisposed) return;

    _uploadingMedia[type] = true;
    _uploadProgressMap[type] = 0.0;
    _safeNotify();

    final dio = DioClient.instance;

    // تحديد نوع API
    String apiType;
    switch (type) {
      case 'thumbnail':
        apiType = 'image';
        break;
      case 'video':
        apiType = 'video';
        break;
      case 'audio':
        apiType = 'audio';
        break;
      default:
        apiType = type;
    }

    File uploadFile = file;

    // ✅ إصلاح: تحويل الصوت فقط وليس جميع أنواع الملفات
    if (type == 'audio' && !file.path.endsWith('.mp3')) {
      uploadFile = await _convertAudioFile(file);
    }

    final formData = FormData.fromMap({
      'type': apiType,
      'file': await MultipartFile.fromFile(
        uploadFile.path,
        filename: path.basename(uploadFile.path),
        contentType: DioMediaType.parse(_getCorrectMimeType(uploadFile, type)),
      ),
      'sort_order': '0',
    });

    try {
      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostMedia, postId);

      debugPrint('🌐 Endpoint: $endpoint');

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
        onSendProgress: (sent, total) {
          if (!_isDisposed && total > 0) {
            _uploadProgressMap[type] = sent / total;
            _safeNotify();
          }
        },
      );

      if (_isDisposed) return;

      debugPrint('✅ Response status: ${response.statusCode}');
      debugPrint('📦 Response data: ${response.data}');

      final statusCode = response.statusCode ?? 0;

      // ✅ إصلاح جوهري: أي استجابة ليست 200/201 تُعتبر فشلاً صريحاً
      // (بعض إعدادات Dio لا ترمي DioException تلقائياً على الأكواد
      // غير الناجحة، لذا كان الرفع يفشل بصمت دون أي رسالة للمستخدم
      // ودون منع نشر المنشور).
      if (statusCode != 200 && statusCode != 201) {
        final msg = _buildMediaErrorMessage(
          statusCode: statusCode,
          responseData: response.data,
          type: type,
        );
        _showSnackBar(msg, isError: true);
        throw Exception(msg);
      }

      String? filePath = (response.data is Map)
          ? (response.data['file_path'] ??
              response.data['url'] ??
              response.data['path'])
          : null;

      if (filePath == null || filePath.isEmpty) {
        final msg =
            'فشل رفع ${_getTypeName(type)}: لم يستلم التطبيق مسار الملف من الخادم';
        _showSnackBar(msg, isError: true);
        throw Exception(msg);
      }

      String cleanPath = _cleanFilePath(filePath);
      String fieldName = type == 'thumbnail' ? 'thumbnail' : '${type}_url';
      await _updatePostField(postId, fieldName, cleanPath);
      debugPrint('✅ Uploaded: $cleanPath');

      _showSnackBar('تم رفع ${_getTypeName(type)} بنجاح');
    } on DioException catch (e) {
      debugPrint('❌ Upload error: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');

      final msg = _buildMediaErrorMessage(
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        type: type,
        dioException: e,
      );
      _showSnackBar(msg, isError: true);
      throw Exception(msg);
    } finally {
      if (!_isDisposed) {
        _uploadingMedia[type] = false;
        _safeNotify();
      }
    }
  }

  /// يبني رسالة خطأ عربية واضحة لفشل رفع ملحق (صورة/فيديو/صوت)
  /// بأمان تام (لا يفترض أن response.data هو JSON/Map، لأن بعض
  /// أخطاء الخادم مثل 413 تُعيد صفحة HTML وليس JSON).
  String _buildMediaErrorMessage({
    required int? statusCode,
    required dynamic responseData,
    required String type,
    DioException? dioException,
  }) {
    final typeName = _getTypeName(type);

    if (statusCode == 413) {
      return 'فشل رفع $typeName: حجم الملف كبير جداً على الخادم. '
          'يرجى اختيار ملف أصغر أو ضغط الفيديو قبل الرفع والمحاولة مرة أخرى.';
    }

    if (statusCode == 422) {
      final serverMsg = _extractServerMessage(responseData);
      return 'فشل رفع $typeName: ${serverMsg.isNotEmpty ? serverMsg : 'بيانات الملف غير صالحة أو صيغته غير مدعومة'}';
    }

    if (statusCode == 415) {
      return 'فشل رفع $typeName: صيغة الملف غير مدعومة من الخادم';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'فشل رفع $typeName: ليست لديك صلاحية القيام بهذا الإجراء، يرجى تسجيل الدخول من جديد';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'فشل رفع $typeName: حدث خطأ في الخادم، يرجى المحاولة لاحقاً';
    }

    if (dioException != null) {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'فشل رفع $typeName: انتهى وقت الاتصال، يرجى التحقق من الإنترنت والمحاولة مرة أخرى';
        case DioExceptionType.receiveTimeout:
          return 'فشل رفع $typeName: انتهى وقت انتظار استجابة الخادم';
        case DioExceptionType.connectionError:
          return 'فشل رفع $typeName: تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
        default:
          break;
      }
    }

    final serverMsg = _extractServerMessage(responseData);
    if (serverMsg.isNotEmpty) {
      return 'فشل رفع $typeName: $serverMsg';
    }

    return 'فشل رفع $typeName، يرجى المحاولة مرة أخرى';
  }

  /// استخراج رسالة خطأ من استجابة الخادم بأمان (فقط إذا كانت JSON/Map)
  String _extractServerMessage(dynamic responseData) {
    if (responseData is Map) {
      if (responseData['message'] is String) {
        return responseData['message'] as String;
      }
      final errors = responseData['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
    }
    return '';
  }

  // دالة مساعدة للحصول على اسم النوع بالعربية
  String _getTypeName(String type) {
    switch (type) {
      case 'thumbnail':
        return 'الصورة المصغرة';
      case 'video':
        return 'الفيديو';
      case 'audio':
        return 'الصوت';
      default:
        return 'الملف';
    }
  }

  Future<File> _compressVideoIfNeeded(File videoFile) async {
    final originalSizeMB = await videoFile.length() / (1024 * 1024);

    if (originalSizeMB > 10) {
      try {
        final compressed = await VideoCompress.compressVideo(
          videoFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
          frameRate: 30,
        );
        if (compressed != null && compressed.file != null) {
          return File(compressed.file!.path);
        }
      } catch (e) {
        debugPrint('⚠️ Video compression failed: $e');
      }
    }
    return videoFile;
  }

  String _cleanFilePath(String filePath) {
    String cleanPath = filePath;

    List<String> prefixesToRemove = [
      '/storage/',
      'storage/',
      '/public/',
      'public/',
      '/app/',
      'app/',
    ];

    for (var prefix in prefixesToRemove) {
      if (cleanPath.startsWith(prefix)) {
        cleanPath = cleanPath.substring(prefix.length);
      }
    }

    if (!cleanPath.startsWith('post-media/') && cleanPath.isNotEmpty) {
      cleanPath = 'post-media/$cleanPath';
    }

    debugPrint('🧹 Cleaned path: $filePath -> $cleanPath');
    return cleanPath;
  }

  Future<void> _updatePostField(int postId, String field, String value) async {
    if (_isDisposed) return;
    final dio = DioClient.instance;
    await dio.put('/api/admin/posts/$postId', data: {field: value});
  }

  // ==================== UTILITIES ====================

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 422) {
        final msg = _extractServerMessage(error.response?.data);
        return msg.isNotEmpty ? msg : 'بيانات غير صالحة';
      }
      if (error.response?.statusCode == 413) {
        return 'حجم الملف كبير جداً على الخادم، يرجى اختيار ملف أصغر والمحاولة مرة أخرى';
      }
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'انتهى وقت الاتصال، يرجى المحاولة مرة أخرى';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'انتهى وقت الاستلام، يرجى المحاولة مرة أخرى';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت';
      }
      final serverMsg = _extractServerMessage(error.response?.data);
      return serverMsg.isNotEmpty
          ? serverMsg
          : (error.message ?? 'حدث خطأ غير متوقع');
    }
    // رسائلنا المخصصة (مثل أخطاء رفع الوسائط) تُبنى عبر Exception('نص عربي واضح')
    // نزيل بادئة "Exception: " الافتراضية حتى تظهر نظيفة للمستخدم.
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  String _handleUploadError(DioException e) {
    if (e.response?.statusCode == 422) {
      final errors = e.response?.data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values.first.first;
      }
      return 'بيانات الملف غير صالحة';
    }
    if (e.response?.statusCode == 413) {
      return 'حجم الملف كبير جداً للخادم';
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'انتهى وقت الاتصال أثناء الرفع';
    }
    return e.message ?? 'فشل رفع الملف';
  }

  void _setActionState(bool inProgress, {bool clearMessages = false}) {
    if (_isDisposed) return;

    bool hasChanges = false;
    if (_isActionInProgress != inProgress) {
      _isActionInProgress = inProgress;
      hasChanges = true;
    }

    if (clearMessages) {
      if (_error != null || _successMessage != null) {
        _error = null;
        _successMessage = null;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _safeNotify();
    }
  }

  void clearError() {
    if (_isDisposed) return;
    if (_error != null) {
      _error = null;
      _safeNotify();
    }
  }

  void clearMessages() {
    if (_isDisposed) return;
    if (_error != null || _successMessage != null) {
      _error = null;
      _successMessage = null;
      _safeNotify();
    }
  }

  // تحديث منشور في القائمة المحلية (للتحديث السريع)
  void _updatePostInList(Post updatedPost) {
    if (_isDisposed) return;
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      _safeNotify();
    }
  }

  // ✅ إصلاح: التحقق من نجاح FFmpeg قبل إرجاع الملف
  Future<File> convertToMp3(File inputFile) async {
    final outputPath = inputFile.path.replaceAll('.m4a', '.mp3');

    final session = await FFmpegKit.execute(
      '-i ${inputFile.path} -codec:a libmp3lame -qscale:a 2 $outputPath',
    );

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      debugPrint('✅ convertToMp3 success: $outputPath');
      return File(outputPath);
    } else {
      debugPrint('⚠️ convertToMp3 failed, returning original');
      return inputFile;
    }
  }
}
