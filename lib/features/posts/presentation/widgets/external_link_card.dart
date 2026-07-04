// lib/new_app/feature/post_details/presentation/widgets/external_link_card.dart
//
// ✅ بطاقة تُعرض للروابط من منصات لا يمكن تشغيلها مباشرة داخل التطبيق
// (Vimeo، فيسبوك، تيك توك، إلخ) مع زر لفتحها خارجيًا
// أضف الحزمة عبر: flutter pub add url_launcher

import 'package:flutter/material.dart';
import 'package:admin_dashboard/core/utils/media_source_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkCard extends StatelessWidget {
  final String url;
  final String? title;

  const ExternalLinkCard({super.key, required this.url, this.title});

  _PlatformInfo _platformInfo() {
    switch (MediaSourceHelper.detectExternalPlatform(url)) {
      case ExternalPlatform.vimeo:
        return const _PlatformInfo(Icons.videocam, 'Vimeo', Color(0xFF1AB7EA));
      case ExternalPlatform.facebook:
        return const _PlatformInfo(
            Icons.facebook, 'Facebook', Color(0xFF1877F2));
      case ExternalPlatform.instagram:
        return const _PlatformInfo(
            Icons.camera_alt, 'Instagram', Color(0xFFC13584));
      case ExternalPlatform.tiktok:
        return const _PlatformInfo(Icons.music_note, 'TikTok', Colors.black87);
      case ExternalPlatform.twitter:
        return const _PlatformInfo(
            Icons.alternate_email, 'X / Twitter', Colors.black87);
      case ExternalPlatform.soundcloud:
        return const _PlatformInfo(
            Icons.audiotrack, 'SoundCloud', Color(0xFFFF5500));
      case ExternalPlatform.spotify:
        return const _PlatformInfo(
            Icons.podcasts, 'Spotify', Color(0xFF1DB954));
      case ExternalPlatform.dailymotion:
        return const _PlatformInfo(
            Icons.ondemand_video, 'Dailymotion', Color(0xFF00AAFF));
      case ExternalPlatform.unknown:
        return const _PlatformInfo(Icons.link, 'رابط خارجي', Colors.teal);
    }
  }

  Future<void> _openLink() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _platformInfo();

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                (title != null && title!.isNotEmpty)
                    ? title!
                    : 'محتوى من ${info.label}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'لا يمكن تشغيل هذا المحتوى داخل التطبيق',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _openLink,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text('فتح على ${info.label}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: info.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _PlatformInfo(this.icon, this.label, this.color);
}
