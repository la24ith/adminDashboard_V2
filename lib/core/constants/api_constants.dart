class ApiConstants {
  static const String baseUrl = 'https://joy-change.octo-tech.co';
  static const String apiBaseUrl = '$baseUrl/api';

  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String user = '/api/auth/user';

  // ✅ مسارات الأدمن الصحيحةs
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminUsers = '/api/admin/users';
  static const String adminPosts = '/api/admin/posts';
  static const String allusersinfo = '/api/admin/subscriptions';
  static const String adminNotifications = '/api/admin/notifications';
  static const String adminAds = '/api/admin/ads';
  static const String adminDevices = '/api/admin/devices';
  static const String adminReports = '/api/admin/reports';
  static const String subscriptions = '/api/admin/subscriptions';
  // ✅ مسارات التقارير
  static const String adminReportsCommitments =
      '/api/admin/reports/commitments';
  static const String adminReportsWeights = '/api/admin/reports/weights';
  static const String adminReportsIdealWeights =
      '/api/admin/reports/ideal-weights';
  static const String adminReportsExpiredSubs =
      '/api/admin/reports/expired-subs';
  static const String adminReportsExportPdf = '/api/admin/reports/export/pdf';
  static const String adminReportsExportExcel =
      '/api/admin/reports/export/excel';

  // ✅ مسارات إدارة الأجهزة
  static const String adminUserDevices = '/api/admin/users/{user_id}/devices';
  static const String adminDevicesBlock =
      '/api/admin/devices/{device_record_id}/block';
  static const String adminDevicesApprove =
      '/api/admin/devices/{device_record_id}/approve';
  static const String adminDevicesDelete =
      '/api/admin/devices/{device_record_id}';
  static const String adminDevicesReset =
      '/api/admin/devices/users/{user_id}/reset-devices';

  // ✅ مسارات إدارة المستخدمين
  static const String adminUserStatus = '/api/admin/users/{user_id}/status';
  static const String adminUserSubscription =
      '/api/admin/users/{user_id}/subscription';
  static const String adminExtendSubscription =
      '/api/admin/users/{user_id}/extend-subscription';

  // ✅ مسارات المنشورات

  static const String adminPostMedia = '/api/admin/posts/{post_id}/media';
  static const String adminPostPublish = '/api/admin/posts/{post_id}/publish';
  static const String adminPostSchedule = '/api/admin/posts/{post_id}/schedule';

  // ✅ إعدادات الوسائط
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 50;
  static const int maxAudioSizeMB = 15;
  static const int imageQuality = 75;
  /* static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';

    if (path.startsWith('http')) return path;

    final cleanBase = baseUrl.replaceAll(RegExp(r'/$'), '');

    final cleanPath =
        path.replaceAll(RegExp(r'^/'), '').replaceAll(RegExp(r'^storage/'), '');

    return '$cleanBase/storage/$cleanPath';
  }*/

  /// يحوّل أي مسار/رابط وسائط قادم من الـ API إلى رابط كامل قابل للعرض:
  ///  - رابط Google Drive → يُحوَّل لرابط thumbnail مباشر (أوثق من
  ///    uc?export=view لعرض الصور داخل Image.network/CachedNetworkImage).
  ///  - رابط كامل آخر (http/https) بما فيه signed-media → يُعاد كما هو.
  ///  - مسار نسبي (public storage، مثل "post-media/13/x.jpg") → يُركَّب
  ///    مع baseUrl + "/storage/". هذا هو شكل الصور دائماً بحسب تأكيد
  ///    الباك اند: "Images continue using public /storage/... URLs"
  ///    (بعكس الفيديو/الصوت المحميين اللذين يصلان كرابط signed-media
  ///    كامل جاهز أصلاً، فلا يدخلان هذا الفرع إطلاقاً).
  /*static String mediaUrl(String url) {
    if (url.isEmpty) return url;

    final uri = Uri.tryParse(url);

    // رابط كامل له scheme (http/https) بالفعل
    if (uri != null && uri.hasScheme) {
      final isGoogleDrive = uri.host.contains('drive.google.com') ||
          uri.host.contains('docs.google.com');

      if (isGoogleDrive) {
        final patterns = [
          RegExp(r'/d/([a-zA-Z0-9_-]+)'),
          RegExp(r'id=([a-zA-Z0-9_-]+)'),
        ];
        for (final pattern in patterns) {
          final match = pattern.firstMatch(url);
          if (match != null) {
            final fileId = match.group(1)!;
            return 'https://drive.google.com/thumbnail?id=$fileId&sz=w2000';
          }
        }
      }

      // رابط كامل عادي (signed-media، أو أي رابط خارجي آخر) → كما هو
      return url;
    }

    // ✅ إصلاح: مسار نسبي بدون scheme (شكل الصور الحالي دائماً)
    final cleanBase = baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanPath =
        url.replaceAll(RegExp(r'^/'), '').replaceAll(RegExp(r'^storage/'), '');
    return '$cleanBase/storage/$cleanPath';
  }*/

  // ✅ دالة لإنشاء روابط بديلة (للمعاينة)
  static List<String> getAlternativeUrls(String path) {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final alternatives = <String>[];

    // الرابط الأصلي
    alternatives.add('$cleanBase/storage/$path');

    // رابط بدون storage
    alternatives.add('$cleanBase/$path');

    // رابط مع private-storage
    alternatives.add('$cleanBase/private-storage/$path');

    return alternatives;
  }

  static String replacePostId(String endpoint, int postId) {
    return endpoint.replaceAll('{post_id}', postId.toString());
  }

  // ✅ مسارات الإشعارات
  static const String adminNotificationsExtend =
      '/api/admin/notifications/{notification_id}/extend';

  // ✅ مسارات الإعلانات
  static const String adminAdsToggle = '/api/admin/ads/{ad_id}/toggle';
  static const String adminAdsClick = '/api/ads/{ad_id}/click';

  // معلمات Pagination
  static const String perPage = 'per_page';
  static const String page = 'page';
  static const String search = 'search';
  static const String status = 'status';

  // ✅ بناء الـ URL مع المعلمات
  static String getSubscriptionsUrl({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) {
    final buffer = StringBuffer('$subscriptions?$perPage=$perPage&$page=$page');
    if (search != null && search.isNotEmpty) {
      buffer.write('&$search=$search');
    }
    if (status != null && status.isNotEmpty) {
      buffer.write('&$status=$status');
    }
    return buffer.toString();
  }
  // استبدل mediaUrl الحالية بهذه النسخة الموحّدة

  static String getFullMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    final cleanBase = baseUrl.replaceAll(RegExp(r'/api/?$'), '');

    // تنظيف المسار
    String cleanPath = path;
    cleanPath = cleanPath.replaceAll(
        RegExp(r'^(/storage/|storage/|/public/|public/)'), '');

    // بناء الرابط النهائي
    return '$cleanBase/storage/$cleanPath';
  }

  // استبدل mediaUrl الحالية بهذه النسخة الموحّدة
  static String mediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // رابط نسبي قادم من الباك-إند بدون http
    if (!url.startsWith('http')) {
      return getFullMediaUrl(url);
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final isGoogleDrive = uri.host.contains('drive.google.com') ||
        uri.host.contains('docs.google.com');

    if (isGoogleDrive) {
      final patterns = [
        RegExp(r'/d/([a-zA-Z0-9_-]+)'),
        RegExp(r'id=([a-zA-Z0-9_-]+)'),
      ];
      for (final pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null) {
          final fileId = match.group(1)!;
          return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
        }
      }
      return url;
    }

    // أي رابط آخر: فرض https دائمًا (بدل تكرار replaceFirst في كل ويدجت)
    return url.replaceFirst('http://', 'https://');
  }
}
