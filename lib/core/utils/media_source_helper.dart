// lib/new_app/core/utils/media_source_helper.dart
//
// ✅ يحدد نوع مصدر الرابط (يوتيوب / غوغل درايف / منصة أخرى / رابط مباشر)
// حتى تقرر الواجهة أي ويدجت تستخدم لعرضه.

import 'package:admin_dashboard/features/posts/data/models/enums/media_type.dart';

/// طريقة العرض المناسبة لهذا الرابط
enum MediaSourceType {
  directImage,
  directVideo,
  directAudio,
  youtube,
  googleDriveVideo,
  googleDriveImage,
  googleDriveGeneric,
  externalLink,
}

/// المنصات الخارجية غير المدعومة للتشغيل المباشر داخل التطبيق
enum ExternalPlatform {
  vimeo,
  facebook,
  instagram,
  tiktok,
  twitter,
  soundcloud,
  spotify,
  dailymotion,
  unknown,
}

class MediaSourceHelper {
  MediaSourceHelper._();

  static final RegExp _youtubeIdRegex = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|embed/|shorts/|v/)|youtu\.be/)([a-zA-Z0-9_-]{6,})',
    caseSensitive: false,
  );

  static final RegExp _driveFileIdRegex = RegExp(
    r'/d/([a-zA-Z0-9_-]+)|[?&]id=([a-zA-Z0-9_-]+)',
  );

  static bool isYoutube(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('m.youtube.com');
  }

  /// يستخرج معرّف الفيديو من رابط يوتيوب بأي صيغة كانت
  static String? extractYoutubeId(String url) {
    final match = _youtubeIdRegex.firstMatch(url);
    return match?.group(1);
  }

  static bool isGoogleDrive(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('drive.google.com') ||
        host.contains('docs.google.com');
  }

  /// يستخرج معرّف الملف من رابط غوغل درايف (يدعم صيغة /d/ID/ وصيغة ?id=ID)
  static String? extractDriveFileId(String url) {
    final match = _driveFileIdRegex.firstMatch(url);
    if (match == null) return null;
    return match.group(1) ?? match.group(2);
  }

  static ExternalPlatform detectExternalPlatform(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';

    if (host.contains('vimeo.com')) return ExternalPlatform.vimeo;
    if (host.contains('facebook.com') || host.contains('fb.watch')) {
      return ExternalPlatform.facebook;
    }
    if (host.contains('instagram.com')) return ExternalPlatform.instagram;
    if (host.contains('tiktok.com')) return ExternalPlatform.tiktok;
    if (host.contains('twitter.com') || host.contains('x.com')) {
      return ExternalPlatform.twitter;
    }
    if (host.contains('soundcloud.com')) return ExternalPlatform.soundcloud;
    if (host.contains('spotify.com')) return ExternalPlatform.spotify;
    if (host.contains('dailymotion.com')) return ExternalPlatform.dailymotion;

    return ExternalPlatform.unknown;
  }

  /// نقطة الدخول الرئيسية: تحدد طريقة عرض الرابط
  /// [url] الرابط القادم من الباك-إند
  /// [fallbackType] نوع الميديا الأصلي (image/video/audio) كما حدده الباك-إند،
  /// يُستخدم فقط عندما لا يكون الرابط من منصة معروفة (يوتيوب/درايف/أخرى)
  static MediaSourceType detect(String url, MediaType fallbackType) {
    if (url.isEmpty) {
      return _fallback(fallbackType);
    }

    if (isYoutube(url)) {
      return MediaSourceType.youtube;
    }

    if (isGoogleDrive(url)) {
      switch (fallbackType) {
        case MediaType.video:
          return MediaSourceType.googleDriveVideo;
        case MediaType.image:
          return MediaSourceType.googleDriveImage;
        case MediaType.audio:
          // الصوت من درايف: لا يوجد ستريمنغ مباشر موثوق، نعرضه كمعاينة WebView
          return MediaSourceType.googleDriveGeneric;
        case MediaType.other:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    }

    // منصات أخرى معروفة لا يمكن تشغيلها مباشرة داخل التطبيق
    if (detectExternalPlatform(url) != ExternalPlatform.unknown) {
      return MediaSourceType.externalLink;
    }

    return _fallback(fallbackType);
  }

  static MediaSourceType _fallback(MediaType fallbackType) {
    switch (fallbackType) {
      case MediaType.video:
        return MediaSourceType.directVideo;
      case MediaType.audio:
        return MediaSourceType.directAudio;
      case MediaType.image:
        return MediaSourceType.directImage;
      case MediaType.other:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
