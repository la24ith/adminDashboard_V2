// lib/features/posts/data/repositories/post_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/post_model.dart';

class PostRepository {
  final Dio _dio = DioClient.instance;

  // Cache للمنشورات مع دعم الصفحات
  Map<int, List<Post>> _cachedPages = {};
  DateTime? _lastCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  // إجمالي عدد المنشورات (للمعلومات)
  int _totalPosts = 0;
  int get totalPosts => _totalPosts;

  bool get _isCacheValid =>
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) < _cacheDuration;

  /// جلب المنشورات مع دعم الترقيم (Pagination)
  Future<List<Post>> getPosts({
    int page = 1,
    int perPage = 20,
    bool forceRefresh = false,
  }) async {
    // التحقق من وجود البيانات في الكاش
    if (!forceRefresh && _isCacheValid && _cachedPages.containsKey(page)) {
      print(
          '📦 Using cached posts from page $page (${_cachedPages[page]!.length} items)');
      return _cachedPages[page]!;
    }

    print('🔄 Fetching posts page $page from API...');

    try {
      final response = await _dio.get(
        ApiConstants.adminPosts,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final List<dynamic> postsData = response.data['data'] ?? [];
      _totalPosts = response.data['total'] ?? 0;

      // تحويل البيانات مباشرة بدون طلبات إضافية
      final List<Post> posts =
          postsData.map((json) => Post.fromJson(json)).toList();

      // تخزين في الكاش
      _cachedPages[page] = posts;
      _lastCacheTime = DateTime.now();

      // تنظيف الكاش القديم (الاحتفاظ بآخر 5 صفحات فقط)
      _cleanOldCachePages(page);

      print(
          '✅ Loaded ${posts.length} posts from page $page (Total: $_totalPosts)');
      return posts;
    } catch (e) {
      print('❌ Error loading posts page $page: $e');
      // في حالة الخطأ، نعيد البيانات المخزنة مؤقتاً إذا وجدت
      if (_cachedPages.containsKey(page)) {
        print('📦 Returning cached fallback for page $page');
        return _cachedPages[page]!;
      }
      return [];
    }
  }

  /// جلب جميع المنشورات (بدون ترقيم - للمناسبات الخاصة)
  Future<List<Post>> getAllPosts({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _cachedPages.isNotEmpty) {
      // جمع جميع المنشورات من جميع الصفحات المخزنة
      final allPosts = <Post>[];
      for (var page in _cachedPages.values) {
        allPosts.addAll(page);
      }
      if (allPosts.isNotEmpty) {
        print('📦 Using cached all posts (${allPosts.length} items)');
        return allPosts;
      }
    }

    print('🔄 Fetching all posts from API...');

    try {
      // جلب الصفحة الأولى لتحديد العدد الإجمالي
      final firstResponse = await _dio.get(
        ApiConstants.adminPosts,
        queryParameters: {'page': 1, 'per_page': 100},
      );

      final List<dynamic> firstPageData = firstResponse.data['data'] ?? [];
      final int total = firstResponse.data['total'] ?? 0;
      final List<Post> allPosts =
          firstPageData.map((json) => Post.fromJson(json)).toList();

      // حساب عدد الصفحات المتبقية
      final int totalPages = (total / 100).ceil();

      // جلب باقي الصفحات بالتوازي
      if (totalPages > 1) {
        final futures = <Future<List<Post>>>[];
        for (int i = 2; i <= totalPages; i++) {
          futures.add(_fetchPage(i, 100));
        }

        final results = await Future.wait(futures);
        for (var pagePosts in results) {
          allPosts.addAll(pagePosts);
        }
      }

      // تحديث الكاش
      _cachedPages.clear();
      _cachedPages[1] = allPosts;
      _lastCacheTime = DateTime.now();

      print('✅ Loaded all ${allPosts.length} posts successfully');
      return allPosts;
    } catch (e) {
      print('❌ Error loading all posts: $e');
      return _getAllCachedPosts();
    }
  }

  /// جلب صفحة محددة (داخلية)
  Future<List<Post>> _fetchPage(int page, int perPage) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminPosts,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final List<dynamic> postsData = response.data['data'] ?? [];
      return postsData.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching page $page: $e');
      return [];
    }
  }

  /// جلب منشور واحد بالمعرف
  /// [forceRefresh] = true يتجاوز الكاش ويجلب دائماً النسخة الكاملة
  /// من GET /api/admin/posts/{id} — مهم لأن النسخة المخزنة في كاش
  /// الصفحات (من GET /api/admin/posts) قد لا تحتوي كل تفاصيل الوسائط
  /// (فيديو/صوت/صور)، بعكس استجابة تفاصيل المنشور المفرد.
  Future<Post> getPostById(int id, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        // محاولة البحث في الكاش أولاً (فقط عند عدم طلب تحديث إجباري)
        final cachedPost = _findPostInCache(id);
        if (cachedPost != null) {
          print('📦 Found post $id in cache');
          return cachedPost;
        }
      }

      print('🔄 Fetching post $id from API...');
      final response = await _dio.get('${ApiConstants.adminPosts}/$id');
      final post = Post.fromJson(response.data['data'] ?? response.data);

      // تحديث الكاش إذا وجد المنشور في صفحة مخزنة
      _updatePostInCache(post);

      return post;
    } catch (e) {
      print('❌ Error loading post $id: $e');
      throw Exception('Failed to load post: $e');
    }
  }

  /// إنشاء منشور جديد
  Future<Post> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post(ApiConstants.adminPosts, data: postData);
      final newPost = Post.fromJson(response.data['data'] ?? response.data);

      // تحديث الكاش بإضافة المنشور الجديد في بداية الصفحة الأولى
      if (_cachedPages.containsKey(1)) {
        _cachedPages[1]!.insert(0, newPost);
      }
      _lastCacheTime = DateTime.now();

      return newPost;
    } catch (e) {
      print('❌ Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  /// تحديث منشور
  Future<Post> updatePost(int id, Map<String, dynamic> postData) async {
    try {
      final response =
          await _dio.put('${ApiConstants.adminPosts}/$id', data: postData);
      final updatedPost = Post.fromJson(response.data['data'] ?? response.data);

      // تحديث المنشور في الكاش
      _updatePostInCache(updatedPost);
      _lastCacheTime = DateTime.now();

      return updatedPost;
    } catch (e) {
      print('❌ Error updating post $id: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  /// حذف منشور
  Future<void> deletePost(int id) async {
    try {
      await _dio.delete('${ApiConstants.adminPosts}/$id');

      // حذف المنشور من الكاش
      for (var page in _cachedPages.keys) {
        _cachedPages[page]?.removeWhere((post) => post.id == id);
      }
      _lastCacheTime = DateTime.now();
    } catch (e) {
      print('❌ Error deleting post $id: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  /// جدولة منشور
  Future<Post> schedulePost(int id, DateTime scheduledDate) async {
    try {
      final endpoint =
          ApiConstants.replacePostId(ApiConstants.adminPostSchedule, id);
      final response = await _dio.put(endpoint, data: {
        'scheduled_for': scheduledDate.toIso8601String(),
      });
      final updatedPost = Post.fromJson(response.data['data'] ?? response.data);

      // تحديث المنشور في الكاش
      _updatePostInCache(updatedPost);
      _lastCacheTime = DateTime.now();

      return updatedPost;
    } catch (e) {
      print('❌ Error scheduling post $id: $e');
      throw Exception('Failed to schedule post: $e');
    }
  }

  // ==================== CACHE HELPER METHODS ====================

  /// البحث عن منشور في الكاش
  Post? _findPostInCache(int id) {
    for (var page in _cachedPages.values) {
      for (var post in page) {
        if (post.id == id) {
          return post;
        }
      }
    }
    return null;
  }

  /// تحديث منشور في الكاش
  void _updatePostInCache(Post updatedPost) {
    for (var page in _cachedPages.keys) {
      final index =
          _cachedPages[page]?.indexWhere((p) => p.id == updatedPost.id);
      if (index != null && index != -1 && _cachedPages[page] != null) {
        _cachedPages[page]![index] = updatedPost;
        break;
      }
    }
  }

  /// حذف منشور من الكاش
  void deletePostFromCache(int postId) {
    for (var page in _cachedPages.keys) {
      _cachedPages[page]?.removeWhere((p) => p.id == postId);
    }
  }

  /// تنظيف صفحات الكاش القديمة (الاحتفاظ بآخر 5 صفحات)
  void _cleanOldCachePages(int currentPage) {
    final pagesToKeep = 5;
    final pages = _cachedPages.keys.toList()..sort();
    while (pages.length > pagesToKeep && pages.isNotEmpty) {
      final oldestPage = pages.removeAt(0);
      if (oldestPage < currentPage - 2) {
        _cachedPages.remove(oldestPage);
      }
    }
  }

  /// الحصول على جميع المنشورات المخزنة مؤقتاً
  List<Post> _getAllCachedPosts() {
    final allPosts = <Post>[];
    for (var page in _cachedPages.values) {
      allPosts.addAll(page);
    }
    return allPosts;
  }

  /// مسح الكاش بالكامل
  void clearCache() {
    _cachedPages.clear();
    _lastCacheTime = null;
    _totalPosts = 0;
    print('🗑️ Cache cleared');
  }

  /// تحديث الكاش بقائمة جديدة
  void updateCache(List<Post> posts, {int page = 1}) {
    _cachedPages[page] = posts;
    _lastCacheTime = DateTime.now();
  }

  /// التحقق من وجود صفحة في الكاش
  bool hasPage(int page) => _cachedPages.containsKey(page);

  /// الحصول على صفحة من الكاش
  List<Post>? getCachedPage(int page) => _cachedPages[page];
}
