// lib/features/posts/presentation/state/posts_controller.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostsController extends ChangeNotifier {
  // Posts data
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _postsPerPage = 20;

  // Actions state
  bool _isActionInProgress = false;
  String? _error;
  String? _successMessage;

  // Repository
  final PostRepository _repository = PostRepository();

  // Media upload tracking
  final Map<String, bool> _uploadingMedia = {};
  final Map<String, double> _uploadProgressMap = {};

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

  PostsController() {
    loadPosts();
  }

  // ==================== POSTS CRUD WITH PAGINATION ====================

  Future<void> loadPosts({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (forceRefresh) {
      _resetPagination();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        perPage: _postsPerPage,
        forceRefresh: forceRefresh,
      );

      if (forceRefresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length == _postsPerPage;
      _error = null;
    } catch (e) {
      _error = _getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final newPosts = await _repository.getPosts(
        page: _currentPage,
        perPage: _postsPerPage,
      );

      if (newPosts.isNotEmpty) {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length == _postsPerPage;
      _error = null;
    } catch (e) {
      _error = _getErrorMessage(e);
      _hasMore = false; // في حالة الخطأ، لا نحاول تحميل المزيد
    } finally {
      _isLoadingMore = false;
      notifyListeners();
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
    DateTime? scheduledFor,
    File? thumbnailFile,
    File? videoFile,
    File? audioFile,
    String? thumbnailUrl,
    String? videoUrl,
    String? audioUrl,
  }) async {
    if (_isActionInProgress) return false;

    _setActionState(true, clearMessages: true);

    try {
      final dio = DioClient.instance;

      final postData = {
        'title': title,
        'content': content,
        'status': status.apiValue,
        if (scheduledFor != null)
          'scheduled_for': scheduledFor.toIso8601String(),
      };

      final response = await dio.post(ApiConstants.adminPosts, data: postData);
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

      _successMessage = 'تم إنشاء المنشور بنجاح';
      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setActionState(false);
    }
  }

  Future<bool> updatePost(
    int postId, {
    String? title,
    String? content,
    PostStatus? status,
    DateTime? scheduledFor,
    File? thumbnailFile,
    File? videoFile,
    File? audioFile,
    String? thumbnailUrl,
    String? videoUrl,
    String? audioUrl,
  }) async {
    if (_isActionInProgress) return false;

    _setActionState(true, clearMessages: true);

    try {
      final dio = DioClient.instance;

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (status != null) updateData['status'] = status.apiValue;
      if (scheduledFor != null)
        updateData['scheduled_for'] = scheduledFor.toIso8601String();

      if (updateData.isNotEmpty) {
        await dio.put('/api/admin/posts/$postId', data: updateData);
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

      _successMessage = 'تم تحديث المنشور';
      _repository.clearCache();
      _resetPagination();
      await loadPosts(forceRefresh: true);
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setActionState(false);
    }
  }

  Future<bool> deletePost(int postId) async {
    if (_isActionInProgress) return false;
    _setActionState(true);

    try {
      final dio = DioClient.instance;
      final response = await dio.delete('/api/admin/posts/$postId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        _repository.deletePostFromCache(postId);
        _posts.removeWhere((post) => post.id == postId);
        _successMessage = 'تم حذف المنشور';
        notifyListeners();
        return true;
      }
      throw Exception('فشل الحذف');
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setActionState(false);
    }
  }

  Future<bool> schedulePost(int postId, DateTime scheduledDate) async {
    if (_isActionInProgress) return false;
    _setActionState(true);

    try {
      final dio = DioClient.instance;
      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostSchedule, postId);
      final response = await dio.put(endpoint, data: {
        'scheduled_for': scheduledDate.toIso8601String(),
      });

      if (response.statusCode == 200) {
        _successMessage = 'تمت الجدولة بنجاح';
        _repository.clearCache();
        _resetPagination();
        await loadPosts(forceRefresh: true);
        return true;
      }
      return false;
    } catch (e) {
      _error = _getErrorMessage(e);
      return false;
    } finally {
      _setActionState(false);
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
    if (thumbnailFile != null) {
      await _uploadMedia(postId, thumbnailFile, 'thumbnail');
    } else if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      await _updatePostField(postId, 'thumbnail', thumbnailUrl);
    }

    // رفع الفيديو
    if (videoFile != null) {
      await _uploadMedia(postId, videoFile, 'video');
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      await _updatePostField(postId, 'video_url', videoUrl);
    }

    // رفع الصوت
    if (audioFile != null) {
      await _uploadMedia(postId, audioFile, 'audio');
    } else if (audioUrl != null && audioUrl.isNotEmpty) {
      await _updatePostField(postId, 'audio_url', audioUrl);
    }
  }

  Future<void> _uploadMedia(int postId, File file, String type) async {
    _uploadingMedia[type] = true;
    _uploadProgressMap[type] = 0.0;
    notifyListeners();

    final dio = DioClient.instance;

    // ضغط الفيديو إذا كان حجمه كبيراً
    File uploadFile = file;
    if (type == 'video') {
      uploadFile = await _compressVideoIfNeeded(file);
    }

    final extension = uploadFile.path.split('.').last;
    final fileName =
        '${type}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    final formData = FormData.fromMap({
      'type': type == 'thumbnail' ? 'image' : type,
      'file': await MultipartFile.fromFile(uploadFile.path, filename: fileName),
      'sort_order': 0,
    });

    try {
      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostMedia, postId);
      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {'ngrok-skip-browser-warning': 'true'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgressMap[type] = sent / total;
            notifyListeners();
          }
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final filePath = response.data['file_path'] ?? response.data['url'];
        if (filePath != null) {
          String cleanPath = _cleanFilePath(filePath);

          // تحديث الحقل المناسب
          switch (type) {
            case 'thumbnail':
              await _updatePostField(postId, 'thumbnail', cleanPath);
              break;
            case 'video':
              await _updatePostField(postId, 'video_url', cleanPath);
              break;
            case 'audio':
              await _updatePostField(postId, 'audio_url', cleanPath);
              break;
          }
          print('✅ $type uploaded: $cleanPath');
        }
      }
    } on DioException catch (e) {
      print('❌ Upload error: ${e.message}');
      throw Exception(_handleUploadError(e));
    } finally {
      _uploadingMedia[type] = false;
      notifyListeners();

      // تنظيف الملف المؤقت
      if (uploadFile.path != file.path && await uploadFile.exists()) {
        await uploadFile.delete();
      }
    }
  }

  Future<File> _compressVideoIfNeeded(File videoFile) async {
    final originalSizeMB = await videoFile.length() / (1024 * 1024);
    print('📹 Original video size: ${originalSizeMB.toStringAsFixed(2)} MB');

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
          final compressedSizeMB =
              await compressedFile.length() / (1024 * 1024);
          print('📹 Compressed: ${compressedSizeMB.toStringAsFixed(2)} MB');
          return compressedFile;
        }
      } catch (e) {
        print('⚠️ Compression failed: $e');
      }
    }
    return videoFile;
  }

  String _cleanFilePath(String path) {
    String cleanPath = path.replaceAll(
      RegExp(r'^(/storage/|storage/|/public/|public/)'),
      '',
    );
    if (!cleanPath.startsWith('post-media')) {
      cleanPath = 'post-media/$cleanPath';
    }
    return cleanPath;
  }

  Future<void> _updatePostField(int postId, String field, String value) async {
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
    _isActionInProgress = inProgress;
    if (clearMessages) {
      _error = null;
      _successMessage = null;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // تحديث منشور في القائمة المحلية (للتحديث السريع)
  void _updatePostInList(Post updatedPost) {
    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index != -1) {
      _posts[index] = updatedPost;
      notifyListeners();
    }
  }
}
