// lib/core/utils/video_provider_detector.dart
//
// أداة مساعدة لاكتشاف مزوّد الفيديو الخارجي من الرابط نفسه، ولبناء
// روابط التضمين (embed) القابلة للعرض داخل WebView حيثما أمكن.
//
// تُستخدم كخط دفاع ثانٍ عندما لا يرسل الخادم حقل "provider" صراحةً
// (مثلاً عندما يُحفظ الرابط في video_url مباشرة على المنشور بدل جدول
// media القديم). عندما يتوفر "provider" من الخادم يجب تفضيله دائماً
// لأنه أدق من أي اكتشاف نصّي من الرابط.
class VideoProviderDetector {
  VideoProviderDetector._();

  static const String youtube = 'youtube';
  static const String vimeo = 'vimeo';
  static const String facebook = 'facebook';
  static const String googleDrive = 'google_drive';

  /// يحاول اكتشاف المزوّد من الرابط. يُعيد null إن لم يتعرّف على أي
  /// مزوّد معروف (تُعامل عندها كـ "منصة أخرى" — فتح خارجي مباشر).
  static String? detect(String? url) {
    if (url == null) return null;
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return null;

    if (u.contains('youtube.com') || u.contains('youtu.be')) {
      return youtube;
    }
    if (u.contains('drive.google.com') || u.contains('docs.google.com/uc')) {
      return googleDrive;
    }
    if (u.contains('vimeo.com')) {
      return vimeo;
    }
    if (u.contains('facebook.com') || u.contains('fb.watch')) {
      return facebook;
    }
    return null;
  }

  /// يستخرج معرّف فيديو يوتيوب من مختلف صيغ الروابط الممكنة
  /// (watch?v=, youtu.be/, embed/, shorts/).
  static String? extractYoutubeId(String url) {
    final patterns = <RegExp>[
      RegExp(r'youtube\.com\/watch\?v=([a-zA-Z0-9_-]{6,})'),
      RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{6,})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{6,})'),
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{6,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    return null;
  }

  /// يستخرج معرّف الملف من رابط غوغل درايف بمختلف صيغه
  /// (/file/d/{id}/..., ?id={id}).
  static String? extractDriveFileId(String url) {
    final patterns = <RegExp>[
      RegExp(r'/file/d/([a-zA-Z0-9_-]+)'),
      RegExp(r'[?&]id=([a-zA-Z0-9_-]+)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    return null;
  }

  static String? _extractVimeoId(String url) {
    final m = RegExp(r'vimeo\.com/(?:.*/)?(\d+)').firstMatch(url);
    return m?.group(1);
  }

  /// يبني رابط التضمين المناسب للعرض داخل WebView حسب المزوّد.
  /// يُعيد null إذا تعذّر بناء رابط تضمين موثوق (عندها يُفضَّل فتح
  /// الرابط الأصلي خارجياً بدلاً من محاولة تضمين قد لا تعمل).
  static String? buildEmbedUrl(String url, String provider) {
    switch (provider) {
      case googleDrive:
        final id = extractDriveFileId(url);
        return id != null
            ? 'https://drive.google.com/file/d/$id/preview'
            : null;
      case facebook:
        return 'https://www.facebook.com/plugins/video.php'
            '?href=${Uri.encodeComponent(url)}&show_text=false&autoplay=false';
      case vimeo:
        final id = _extractVimeoId(url);
        return id != null ? 'https://player.vimeo.com/video/$id' : null;
      default:
        return null;
    }
  }

  /// اسم المزوّد بالعربية لعرضه في الواجهة.
  static String arabicLabel(String? provider) {
    switch (provider) {
      case youtube:
        return 'يوتيوب';
      case googleDrive:
        return 'غوغل درايف';
      case vimeo:
        return 'فيميو';
      case facebook:
        return 'فيسبوك';
      default:
        return 'منصة خارجية';
    }
  }
}
