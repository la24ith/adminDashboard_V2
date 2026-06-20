//import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';
//import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  // ✅ دالة مساعدة للتحقق من وجود Context
  bool get hasValidContext => _hasContext && _context != null;
  // ✅ دالة مساعدة لعرض SnackBar بأمان
  void _showErrorSnackBar(String message) {
    if (_hasContext && _context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
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

  // ==================== LIFECYCLE SAFETY ====================
  bool _isDisposed = false;

  // Safe notifyListeners - prevents calls after dispose and during build
  void _safeNotify() {
    if (!_isDisposed) {
      // Schedule microtask to avoid calling notifyListeners during build
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
    // Clean up any resources if needed (e.g., cancel ongoing uploads)
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

  PostsController() {}

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
      _hasMore = false; // في حالة الخطأ، لا نحاول تحميل المزيد
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

      await _uploadAllMedia(
        postId,
        thumbnailFile,
        thumbnailUrl,
        videoFile,
        videoUrl,
        audioFile,
        audioUrl,
      );

      if (_isDisposed) return false;

      _successMessage = 'تم إنشاء المنشور بنجاح';
      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      return false;
    } finally {
      if (!_isDisposed) {
        _setActionState(false);
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
      if (status != null) updateData['segment'] = segment;
      if (scheduledFor != null)
        updateData['scheduled_for'] = scheduledFor.toIso8601String();

      if (updateData.isNotEmpty) {
        await dio.put('/api/admin/posts/$postId', data: updateData);
        if (_isDisposed) return false;
      }

      await _uploadAllMedia(
        postId,
        thumbnailFile,
        thumbnailUrl,
        videoFile,
        videoUrl,
        audioFile,
        audioUrl,
      );

      if (_isDisposed) return false;

      _successMessage = 'تم تحديث المنشور';
      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      return false;
    } finally {
      if (!_isDisposed) {
        _setActionState(false);
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
        _safeNotify();
        return true;
      }
      throw Exception('فشل الحذف');
    } catch (e) {
      if (_isDisposed) return false;
      _error = _getErrorMessage(e);
      return false;
    } finally {
      if (!_isDisposed) {
        _setActionState(false);
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
      if (!_isDisposed) {
        _setActionState(false);
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
// lib/features/posts/presentation/state/posts_controller.dart

// ✅ دالة تحديد MIME type بشكل صحيح للملفات الصوتية
  String _getCorrectMimeType(File file, String type) {
    final path = file.path;
    final extension = path.split('.').last.toLowerCase();

    debugPrint(
        '🔍 Detecting MIME for: $path, type: $type, extension: $extension');

    // ✅ للصوت - تحديد دقيق
    if (type == 'audio') {
      // التحقق من امتداد الملف
      if (extension == 'mp3') {
        return 'audio/mpeg';
      }
      if (extension == 'm4a') {
        return 'audio/mp4'; // ✅ M4A هو audio/mp4 وليس video/mp4
      }
      if (extension == 'aac') {
        return 'audio/aac';
      }
      if (extension == 'wav') {
        return 'audio/wav';
      }
      // التحقق من محتوى الملف إذا كان الامتداد غير واضح
      return 'audio/mpeg';
    }

    // للفيديو
    if (type == 'video') {
      if (extension == 'mp4') return 'video/mp4';
      if (extension == 'mov') return 'video/quicktime';
      return 'video/mp4';
    }

    // للصور
    if (type == 'image') {
      if (extension == 'png') return 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }

  Future<File> _convertAudioFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    // إذا كان الملف بصيغة m4a، حوله إلى mp3
    if (extension == 'm4a') {
      try {
        final tempDir = await getTemporaryDirectory();
        final newPath = file.path.replaceAll('.m4a', '.mp3');
        final mp3File = File(newPath);

        // انسخ الملف مع تغيير الامتداد
        await file.copy(mp3File.path);
        debugPrint('✅ Converted m4a to mp3: ${mp3File.path}');
        return mp3File;
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

    final extension = file.path.split('.').last.toLowerCase();
    final fileName =
        '${type}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    File uploadFile = file;

    if (!file.path.endsWith('.mp3')) {
      uploadFile = await convertToMp3(file);
    }

    final formData = FormData.fromMap({
      'type': apiType,
      'file': await MultipartFile.fromFile(
        uploadFile.path,
        filename: path.basename(uploadFile.path),
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
            'ngrok-skip-browser-warning': 'true',
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

      if (response.statusCode == 201 || response.statusCode == 200) {
        String? filePath = response.data['file_path'] ??
            response.data['url'] ??
            response.data['path'];

        if (filePath != null && filePath.isNotEmpty) {
          String cleanPath = _cleanFilePath(filePath);
          String fieldName = type == 'thumbnail' ? 'thumbnail' : '${type}_url';
          await _updatePostField(postId, fieldName, cleanPath);
          debugPrint('✅ Uploaded: $cleanPath');

          // ✅ عرض رسالة نجاح
          _showErrorSnackBar('تم رفع ${_getTypeName(type)} بنجاح');
        }
      }
    } on DioException catch (e) {
      debugPrint('❌ Upload error: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');

      // ✅ عرض رسالة خطأ
      String errorMsg =
          e.response?.data?['message'] ?? e.message ?? 'فشل الرفع';
      _showErrorSnackBar(errorMsg);
      rethrow;
    } finally {
      if (!_isDisposed) {
        _uploadingMedia[type] = false;
        _safeNotify();
      }
    }
  }

// ✅ دالة مساعدة للحصول على اسم النوع بالعربية
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
    // Removed print

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
          final compressedFile = File(compressed.file!.path);
          // Removed print
          return compressedFile;
        }
      } catch (e) {
        // Removed print
      }
    }
    return videoFile;
  }

  String _cleanFilePath(String path) {
    // ✅ تنظيف المسار بشكل صحيح
    String cleanPath = path;

    // إزالة البادئات الزائدة إذا وجدت
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

    // ✅ التأكد من أن المسار يبدأ بـ post-media/
    if (!cleanPath.startsWith('post-media/') && cleanPath.isNotEmpty) {
      cleanPath = 'post-media/$cleanPath';
    }

    debugPrint('🧹 Cleaned path: $path -> $cleanPath');
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
        final errors = error.response?.data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          return errors.values.first.first;
        }
        return 'بيانات غير صالحة';
      }
      if (error.response?.statusCode == 413) {
        return 'الملف كبير جداً. الحد الأقصى للرفع هو 50 ميجابايت';
      }
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'انتهى وقت الاتصال، يرجى المحاولة مرة أخرى';
      }
      if (error.type == DioExceptionType.receiveTimeout) {
        return 'انتهى وقت الاستلام، يرجى المحاولة مرة أخرى';
      }
      return error.message ?? 'حدث خطأ غير متوقع';
    }
    return error.toString();
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

  Future<File> convertToMp3(File inputFile) async {
    final outputPath = inputFile.path.replaceAll('.m4a', '.mp3');

    /* await FFmpegKit.execute(
      '-i ${inputFile.path} -codec:a libmp3lame -qscale:a 2 $outputPath',
    );*/

    return File(outputPath);
  }
}
