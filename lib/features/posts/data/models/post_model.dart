// lib/features/posts/data/models/post_model.dart
import 'package:equatable/equatable.dart';

enum PostStatus { published, scheduled, draft }

extension PostStatusExtension on PostStatus {
  String get apiValue {
    switch (this) {
      case PostStatus.published:
        return 'published';
      case PostStatus.scheduled:
        return 'scheduled';
      case PostStatus.draft:
        return 'draft';
    }
  }

  String get arabicName {
    switch (this) {
      case PostStatus.published:
        return 'منشور';
      case PostStatus.scheduled:
        return 'مجدول';
      case PostStatus.draft:
        return 'مسودة';
    }
  }
}

class PostMedia extends Equatable {
  final int id;
  final int postId;
  final String type;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String? mimeType;
  final int? duration;
  final String? thumbnail;
  final int sortOrder;
  final bool isDownloadable;
  final String createdAt;

  const PostMedia({
    required this.id,
    required this.postId,
    required this.type,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.mimeType,
    this.duration,
    this.thumbnail,
    required this.sortOrder,
    required this.isDownloadable,
    required this.createdAt,
  });

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: json['id'],
      postId: json['post_id'],
      type: json['type'],
      // ✅ إصلاح جوهري: الـ API الحالي لا يرجع حقل "file_path" إطلاقاً
      // ضمن عناصر media (تحقّقنا من الـ response الفعلي)، بل يرجع
      // "file_url" أو "url" — وهما رابط signed-media كامل وجاهز
      // للاستخدام مباشرة. كان الكود يقرأ file_path دائماً فيحصل على
      // '' (فارغة)، فيرسل الفيديو/الصوت طلباً لجذر الدومين بدون أي
      // مسار (نفس خطأ 404/ROUTE_NOT_FOUND الذي شاهدناه).
      // نُبقي على الترتيب: file_url أولاً، ثم url، ثم file_path كـ
      // fallback أخير في حال أضافه الباك اند لاحقاً بشكل مختلف.
      filePath: (json['file_url'] ?? json['url'] ?? json['file_path'] ?? '')
          as String,
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      mimeType: json['mime_type'],
      duration: json['duration'],
      thumbnail: json['thumbnail'],
      sortOrder: json['sort_order'] ?? 0,
      isDownloadable: json['is_downloadable'] ?? true,
      createdAt: json['created_at'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, postId, type, filePath];
}

class PostAuthor extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  const PostAuthor({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.role,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
    );
  }

  @override
  List<Object?> get props => [id, name, email, role];
}

class Post extends Equatable {
  final int id;
  final String title;
  final String content;
  final String segment;
  final String? thumbnail;
  final PostStatus status;
  final DateTime? publishedAt;
  final DateTime? scheduledFor;
  final int viewCount;
  final bool isFeatured;
  final bool allowDownload;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostAuthor? author;
  final List<PostMedia> media;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.segment,
    this.thumbnail,
    required this.status,
    this.publishedAt,
    this.scheduledFor,
    this.viewCount = 0,
    this.isFeatured = false,
    this.allowDownload = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.media = const [],
  });

  bool get hasVideo => media.any((m) => m.isVideo);
  bool get hasAudio => media.any((m) => m.isAudio);
  bool get hasImages => media.any((m) => m.isImage);
  bool get hasThumbnail => thumbnail != null && thumbnail!.isNotEmpty;

  String get displayDate =>
      publishedAt != null ? _formatDate(publishedAt!) : _formatDate(createdAt);

  PostMedia? get firstVideo {
    for (final m in media) {
      if (m.isVideo) return m;
    }
    return null;
  }

  PostMedia? get firstAudio {
    for (final m in media) {
      if (m.isAudio) return m;
    }
    return null;
  }

  PostMedia? get firstImage {
    for (final m in media) {
      if (m.isImage) return m;
    }
    return null;
  }

  String? get videoUrl {
    final video = firstVideo;
    return video?.filePath;
  }

  String? get audioUrl {
    final audio = firstAudio;
    return audio?.filePath;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  factory Post.fromJson(Map<String, dynamic> json) {
    List<PostMedia> mediaList = [];

    if (json['media'] != null && json['media'] is List) {
      for (var mediaJson in json['media']) {
        mediaList.add(PostMedia.fromJson(mediaJson));
      }
    }

    PostStatus status = PostStatus.draft;
    switch (json['status']) {
      case 'published':
        status = PostStatus.published;
        break;
      case 'scheduled':
        status = PostStatus.scheduled;
        break;
      default:
        status = PostStatus.draft;
    }

    PostAuthor? author;
    if (json['author'] != null) {
      author = PostAuthor.fromJson(json['author']);
    }

    return Post(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      thumbnail: json['thumbnail'],
      status: status,
      segment: json['segment'] ?? 'general',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.tryParse(json['scheduled_for'])
          : null,
      viewCount: json['view_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      allowDownload: json['allow_download'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      author: author,
      media: mediaList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'status': status.apiValue,
      if (scheduledFor != null)
        'scheduled_for': scheduledFor!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        thumbnail,
        status,
        publishedAt,
        scheduledFor,
        viewCount,
        isFeatured,
        allowDownload,
        sortOrder,
        createdAt,
        updatedAt,
        author,
        media
      ];
}
