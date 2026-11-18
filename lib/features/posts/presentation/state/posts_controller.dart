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
    // ✅ عند إنشاء منشور جديد لا يوجد وسيط سابق بعد، لذا يبقى null دائماً.
    // أُبقي البارامتر هنا فقط للتوافق مع نفس توقيع updatePost.
    int? existingVideoMediaId,
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
          existingVideoMediaId: existingVideoMediaId,
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
    // ✅ معرّف عنصر الفيديو الحالي (من جدول media) إن وُجد مسبقاً على
    // هذا المنشور، سواء كان مرفوعاً أو خارجياً. يُستخدم لتحديد ما إذا
    // كان يجب إنشاء عنصر فيديو خارجي جديد أم تحديث العنصر الموجود
    // (PUT /api/admin/posts/media/{media_id}) بدل تكرار السجلات.
    int? existingVideoMediaId,
    // ✅ جديد: معرّفات عناصر الوسائط الحالية (من جدول media) للصورة
    // المصغّرة والصوت، تُستخدم لحذف/استبدال العنصر القديم بدل تكرار
    // إنشاء عناصر جديدة في كل مرة يُعدَّل فيها المنشور.
    int? existingThumbnailMediaId,
    int? existingAudioMediaId,
    // ✅ جديد: تُمرَّر true عندما يُلغي المستخدم وسيطاً كان موجوداً
    // مسبقاً (بدون اختيار بديل)، حتى نحذفه فعلياً من الخادم بدل ترك
    // القيمة القديمة كما هي.
    bool removeThumbnail = false,
    bool removeVideo = false,
    bool removeAudio = false,
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
          existingVideoMediaId: existingVideoMediaId,
          existingThumbnailMediaId: existingThumbnailMediaId,
          existingAudioMediaId: existingAudioMediaId,
          removeThumbnail: removeThumbnail,
          removeVideo: removeVideo,
          removeAudio: removeAudio,
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
    String? audioUrl, {
    int? existingVideoMediaId,
    int? existingThumbnailMediaId,
    int? existingAudioMediaId,
    bool removeThumbnail = false,
    bool removeVideo = false,
    bool removeAudio = false,
  }) async {
    // ✅ الملفات الجديدة تُجمع هنا ثم تُرفع كلها في طلب واحد بالشكل
    // media[i][type] / media[i][file] (انظر _uploadMediaBatch). رفعها
    // بنفس اسم الحقل `file` يجعل PHP يحتفظ بملف واحد فقط.
    final pendingUploads = <_PendingUpload>[];

    // ==================== الصورة المصغّرة ====================
    if (thumbnailFile != null && !_isDisposed) {
      // ✅ إن وُجد عنصر صورة سابق في جدول media نحذفه أولاً قبل رفع
      // الجديد، حتى لا تتراكم عناصر صور قديمة مع كل تعديل للمنشور.
      if (existingThumbnailMediaId != null) {
        await _deleteMediaItem(existingThumbnailMediaId);
        if (_isDisposed) return;
      }
      pendingUploads.add(_PendingUpload('thumbnail', thumbnailFile));
    } else if (thumbnailUrl != null &&
        thumbnailUrl.isNotEmpty &&
        !_isDisposed) {
      // ✅ رابط صورة جديد يحل محل الصورة القديمة: نحذف عنصر media
      // القديم (إن وجد) حتى لا يبقى ظاهراً بجانب الرابط الجديد.
      if (existingThumbnailMediaId != null) {
        await _deleteMediaItem(existingThumbnailMediaId);
        if (_isDisposed) return;
      }
      await _updatePostField(postId, 'thumbnail', thumbnailUrl);
    } else if (removeThumbnail && !_isDisposed) {
      // ✅ المستخدم ألغى الصورة المصغّرة ولم يضع بديلاً: يجب حذفها
      // فعلياً من الخادم (عنصر media إن وُجد + الحقل النصي) بدل ترك
      // القيمة القديمة كما هي.
      if (existingThumbnailMediaId != null) {
        await _deleteMediaItem(existingThumbnailMediaId);
        if (_isDisposed) return;
      }
      await _updatePostField(postId, 'thumbnail', null);
    }

    // ==================== الفيديو ====================
    if (videoFile != null && !_isDisposed) {
      // ✅ فيديو جديد مرفوع كملف يحل محل أي فيديو سابق (مرفوع أو
      // خارجي)؛ نحذف العنصر القديم أولاً لتفادي التكرار أو بقاء
      // الفيديو القديم ظاهراً مع الجديد.
      if (existingVideoMediaId != null) {
        await _deleteMediaItem(existingVideoMediaId);
        if (_isDisposed) return;
      }
      pendingUploads.add(_PendingUpload('video', videoFile));
    } else if (videoUrl != null && videoUrl.isNotEmpty && !_isDisposed) {
      // ✅ رابط فيديو خارجي (يوتيوب/فيميو/فيسبوك) يُنشأ أو يُحدَّث كعنصر
      // ضمن جدول media (POST أو PUT /api/admin/posts/media/{id})، وهذا
      // يُحدِّث العنصر الموجود في مكانه فيغطي أيضاً حالة "فيديو مرفوع
      // سابقاً واستُبدل برابط خارجي" دون ترك نسخة قديمة.
      await _saveExternalVideo(
        postId,
        videoUrl,
        existingMediaId: existingVideoMediaId,
      );
    } else if (removeVideo && !_isDisposed) {
      // ✅ المستخدم ألغى الفيديو (استبدله بصورة مثلاً أو أزاله فقط):
      // يجب حذف عنصر الفيديو من جدول media وتصفير الحقل النصي
      // video_url على المنشور، وإلا يبقى الفيديو القديم ظاهراً بجانب
      // أي وسيط جديد تمت إضافته.
      if (existingVideoMediaId != null) {
        await _deleteMediaItem(existingVideoMediaId);
        if (_isDisposed) return;
      }
      await _updatePostField(postId, 'video_url', null);
    }

    // ==================== الصوت ====================
    if (audioFile != null && !_isDisposed) {
      if (existingAudioMediaId != null) {
        await _deleteMediaItem(existingAudioMediaId);
        if (_isDisposed) return;
      }
      pendingUploads.add(_PendingUpload('audio', audioFile));
    } else if (audioUrl != null && audioUrl.isNotEmpty && !_isDisposed) {
      if (existingAudioMediaId != null) {
        await _deleteMediaItem(existingAudioMediaId);
        if (_isDisposed) return;
      }
      await _updatePostField(postId, 'audio_url', audioUrl);
    } else if (removeAudio && !_isDisposed) {
      // ✅ المستخدم ألغى المقطع الصوتي: نحذف عنصر media الخاص به (إن
      // وُجد) ونصفّر الحقل النصي audio_url على المنشور.
      if (existingAudioMediaId != null) {
        await _deleteMediaItem(existingAudioMediaId);
        if (_isDisposed) return;
      }
      await _updatePostField(postId, 'audio_url', null);
    }

    // ==================== رفع كل الملفات الجديدة دفعة واحدة ====================
    if (pendingUploads.isNotEmpty && !_isDisposed) {
      await _uploadMediaBatch(postId, pendingUploads);
    }
  }

  /// يحذف عنصر وسائط واحداً من جدول media عبر
  /// DELETE /api/admin/posts/media/{media_id}. يُستخدم عند إلغاء وسيط
  /// (صورة/فيديو/صوت) أو استبداله بنوع مختلف تماماً، لضمان عدم بقاء
  /// العنصر القديم ظاهراً بجانب الوسيط الجديد أو بعد الحذف.
  Future<void> _deleteMediaItem(int mediaId) async {
    if (_isDisposed) return;
    final dio = DioClient.instance;
    try {
      await dio.delete('${ApiConstants.adminPosts}/media/$mediaId');
    } on DioException catch (e) {
      // ✅ إن كان العنصر محذوفاً مسبقاً من الخادم (404) نعتبرها نجاحاً
      // صامتاً بدل إيقاف عملية الحفظ بالكامل بسبب حالة سباق بسيطة.
      if (e.response?.statusCode == 404) {
        debugPrint('ℹ️ عنصر الوسائط $mediaId غير موجود أصلاً على الخادم');
        return;
      }
      final msg = _buildMediaErrorMessage(
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        type: 'media',
        dioException: e,
      );
      _showSnackBar(msg, isError: true);
      throw Exception(msg);
    }
  }

  /// ينشئ عنصر فيديو خارجي جديد ضمن جدول media الخاص بالمنشور، أو يحدّث
  /// العنصر الموجود مسبقاً (سواء كان مرفوعاً أو خارجياً) إذا تم تمرير
  /// [existingMediaId] — هذا يغطي الحالتين:
  /// - إضافة رابط فيديو خارجي لأول مرة (POST)
  /// - تعديل رابط خارجي حالي، أو استبدال فيديو مرفوع برابط خارجي (PUT)
  Future<void> _saveExternalVideo(
    int postId,
    String url, {
    int? existingMediaId,
  }) async {
    if (_isDisposed) return;

    _uploadingMedia['video'] = true;
    _safeNotify();

    final dio = DioClient.instance;
    final data = {
      'type': 'video',
      'source_type': 'external',
      'external_url': url,
      if (existingMediaId == null) 'sort_order': 0,
    };

    try {
      if (existingMediaId != null) {
        // PUT /api/admin/posts/media/{media_id}
        await dio.put(
          '${ApiConstants.adminPosts}/media/$existingMediaId',
          data: data,
        );
      } else {
        // POST /api/admin/posts/{post_id}/media
        final endpoint =
            ApiConstants.replacePostId(ApiConstants.adminPostMedia, postId);
        await dio.post(endpoint, data: data);
      }
      _showSnackBar('تم حفظ رابط الفيديو الخارجي بنجاح');
    } on DioException catch (e) {
      // ✅ 422 = رابط غير مدعوم أو غير صالح بحسب المواصفة الجديدة
      String msg;
      if (e.response?.statusCode == 422) {
        final serverMsg = _extractServerMessage(e.response?.data);
        msg = 'فشل حفظ رابط الفيديو: '
            '${serverMsg.isNotEmpty ? serverMsg : 'الرابط غير مدعوم (يُقبل يوتيوب / فيميو / فيسبوك فقط)'}';
      } else {
        msg = _buildMediaErrorMessage(
          statusCode: e.response?.statusCode,
          responseData: e.response?.data,
          type: 'video',
          dioException: e,
        );
      }
      _showSnackBar(msg, isError: true);
      throw Exception(msg);
    } finally {
      if (!_isDisposed) {
        _uploadingMedia['video'] = false;
        _safeNotify();
      }
    }
  }

  // دالة تحديد MIME type بشكل صحيح للملفات
  String _getCorrectMimeType(File file, String type) {
    final filePath = file.path;
    final extension = filePath.split('.').last.toLowerCase();

    debugPrint(
        '🔍 Detecting MIME for: $filePath, type: $type, extension: $extension');

    if (type == 'audio') {
      // الصيغ التي يقبلها الخادم:
      // mp3, wav, m4a, m4b, mp4, aac, ogg, oga, opus, 3gp, 3gpp, amr, wma, flac
      const audioMimes = {
        'mp3': 'audio/mpeg',
        'wav': 'audio/wav',
        'm4a': 'audio/mp4',
        'm4b': 'audio/mp4',
        'mp4': 'audio/mp4',
        'aac': 'audio/aac',
        'ogg': 'audio/ogg',
        'oga': 'audio/ogg',
        'opus': 'audio/opus',
        '3gp': 'audio/3gpp',
        '3gpp': 'audio/3gpp',
        'amr': 'audio/amr',
        'wma': 'audio/x-ms-wma',
        'flac': 'audio/flac',
      };
      return audioMimes[extension] ?? 'audio/mpeg';
    }

    if (type == 'video') {
      if (extension == 'mp4') return 'video/mp4';
      if (extension == 'mov') return 'video/quicktime';
      return 'video/mp4';
    }

    if (type == 'image') {
      if (extension == 'png') return 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') return 'image/jpeg';
      if (extension == 'webp') return 'image/webp';
      if (extension == 'gif') return 'image/gif';
      return 'image/jpeg';
    }

    return 'application/octet-stream';
  }

  /// يرفع كل الملفات الجديدة في طلب multipart واحد إلى
  /// POST /api/admin/posts/{id}/media بالشكل:
  ///   media[0][type] = image   media[0][file] = <ملف>
  ///   media[1][type] = audio   media[1][file] = <ملف>
  /// لا نضبط Content-Type يدوياً؛ Dio يضيف multipart/form-data مع الـ boundary.
  /// الرد: كائن واحد عند رفع ملف واحد، ومصفوفة عند رفع أكثر من ملف.
  Future<void> _uploadMediaBatch(
    int postId,
    List<_PendingUpload> uploads,
  ) async {
    if (_isDisposed || uploads.isEmpty) return;

    final keys = uploads.map((u) => u.key).toList();
    // اسم يُستخدم في رسائل الخطأ: نوع الملف إن كان واحداً، وإلا "الوسائط"
    final errorType = keys.length == 1 ? keys.first : 'media';

    for (final key in keys) {
      _uploadingMedia[key] = true;
      _uploadProgressMap[key] = 0.0;
    }
    _safeNotify();

    final dio = DioClient.instance;

    try {
      final formData = FormData();
      for (var i = 0; i < uploads.length; i++) {
        final upload = uploads[i];
        formData.fields.add(MapEntry('media[$i][type]', upload.apiType));
        formData.fields.add(MapEntry('media[$i][sort_order]', '$i'));
        formData.files.add(MapEntry(
          'media[$i][file]',
          await MultipartFile.fromFile(
            upload.file.path,
            filename: path.basename(upload.file.path),
            contentType: DioMediaType.parse(
              _getCorrectMimeType(upload.file, upload.apiType),
            ),
          ),
        ));
      }

      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostMedia, postId);
      debugPrint('🌐 Endpoint: $endpoint (${uploads.length} file(s): $keys)');

      final response = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
        onSendProgress: (sent, total) {
          if (!_isDisposed && total > 0) {
            for (final key in keys) {
              _uploadProgressMap[key] = sent / total;
            }
            _safeNotify();
          }
        },
      );

      if (_isDisposed) return;

      final statusCode = response.statusCode ?? 0;
      debugPrint('✅ Response status: $statusCode');

      // validateStatus في DioClient لا يرمي على 4xx، لذا نفحص يدوياً
      if (statusCode != 200 && statusCode != 201) {
        final msg = _buildMediaErrorMessage(
          statusCode: statusCode,
          responseData: response.data,
          type: errorType,
        );
        _showSnackBar(msg, isError: true);
        throw Exception(msg);
      }

      final uploaded = _parseUploadedMedia(response.data);

      // ✅ تحديث الحقول النصية القديمة على المنشور (thumbnail / video_url /
      // audio_url) كما كان سابقاً، للتوافق مع النسخ القديمة من تطبيق المريض.
      for (var i = 0; i < uploads.length; i++) {
        final upload = uploads[i];
        final item = _matchUploadedItem(uploaded, upload, i);
        final filePath = item == null
            ? null
            : (item['file_path'] ?? item['url'] ?? item['path'])?.toString();

        if (filePath == null || filePath.isEmpty) {
          final msg = 'فشل رفع ${_getTypeName(upload.key)}: '
              'لم يستلم التطبيق بيانات الملف من الخادم';
          _showSnackBar(msg, isError: true);
          throw Exception(msg);
        }

        final fieldName =
            upload.key == 'thumbnail' ? 'thumbnail' : '${upload.key}_url';
        await _updatePostField(postId, fieldName, _cleanFilePath(filePath));
        if (_isDisposed) return;
      }

      _showSnackBar(keys.length == 1
          ? 'تم رفع ${_getTypeName(keys.first)} بنجاح'
          : 'تم رفع الوسائط بنجاح');
    } on DioException catch (e) {
      debugPrint('❌ Upload error: ${e.response?.statusCode}');
      final msg = _buildMediaErrorMessage(
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        type: errorType,
        dioException: e,
      );
      _showSnackBar(msg, isError: true);
      throw Exception(msg);
    } finally {
      if (!_isDisposed) {
        for (final key in keys) {
          _uploadingMedia[key] = false;
        }
        _safeNotify();
      }
    }
  }

  /// يحوّل رد رفع الوسائط إلى قائمة عناصر سواء جاء كائناً واحداً أو
  /// مصفوفة، مغلّفاً بـ {data: ...} أو لا، أو كائن منشور فيه media.
  List<Map<String, dynamic>> _parseUploadedMedia(dynamic body) {
    dynamic data = body;
    if (data is Map && data.containsKey('data')) data = data['data'];
    if (data is Map && data['media'] is List) data = data['media'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (data is Map) return [Map<String, dynamic>.from(data)];
    return const [];
  }

  /// يطابق الملف المرفوع رقم [index] مع عنصره في الرد: بنفس الترتيب
  /// والنوع إن أمكن، وإلا بأول عنصر من نفس النوع.
  Map<String, dynamic>? _matchUploadedItem(
    List<Map<String, dynamic>> items,
    _PendingUpload upload,
    int index,
  ) {
    if (items.isEmpty) return null;
    if (items.length == 1) return items.first;
    for (final item in items) {
      if (item['sort_order']?.toString() == '$index' &&
          item['type']?.toString() == upload.apiType) {
        return item;
      }
    }
    for (final item in items) {
      if (item['type']?.toString() == upload.apiType) return item;
    }
    return index < items.length ? items[index] : null;
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
      return 'فشل رفع $typeName: حجم الطلب أكبر من حدود الخادم. '
          'يرجى اختيار ملف أصغر أو ضغط الفيديو/الصوت قبل الرفع والمحاولة مرة أخرى.';
    }

    if (statusCode == 422) {
      final code =
          responseData is Map ? responseData['code']?.toString() : null;
      final reason = switch (code) {
        'MEDIA_UPLOAD_FAILED' => 'فشل رفع أحد الملفات، غالباً بسبب حجمه الكبير',
        'MEDIA_TYPE_MISMATCH' => 'نوع الملف أو امتداده غير مدعوم',
        'MEDIA_TYPE_REQUIRED' => 'لم يتم تحديد نوع الملف',
        _ => null,
      };
      final details = _extractServerDetails(responseData);
      final parts = [
        if (reason != null) reason,
        if (details.isNotEmpty) details,
      ];
      return 'فشل رفع $typeName: ${parts.isNotEmpty ? parts.join('\n') : 'بيانات الملف غير صالحة أو صيغته غير مدعومة'}';
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

  /// يجمع message وكل رسائل errors من رد الخادم (للأخطاء 422) حتى لا
  /// يُخفى سبب فشل أي ملف.
  String _extractServerDetails(dynamic responseData) {
    if (responseData is! Map) return '';
    final lines = <String>[];
    final message = responseData['message'];
    if (message is String && message.isNotEmpty) lines.add(message);
    final errors = responseData['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List) {
          lines.addAll(value.map((e) => e.toString()));
        } else if (value != null) {
          lines.add(value.toString());
        }
      }
    }
    return lines.toSet().join('\n');
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
      case 'media':
        return 'الوسائط';
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

  /// يُحدّث حقلاً نصياً واحداً على المنشور. [value] قد تكون null لتصفير
  /// الحقل فعلياً على الخادم (يُستخدم عند إلغاء وسيط سابق).
  Future<void> _updatePostField(
    int postId,
    String field,
    String? value,
  ) async {
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
}

/// ملف جديد بانتظار الرفع ضمن طلب الوسائط الموحّد.
/// [key] مفتاح الواجهة (thumbnail / video / audio)، و[apiType] النوع
/// المُرسل للخادم في media[i][type].
class _PendingUpload {
  final String key;
  final File file;

  _PendingUpload(this.key, this.file);

  String get apiType => key == 'thumbnail' ? 'image' : key;
}
