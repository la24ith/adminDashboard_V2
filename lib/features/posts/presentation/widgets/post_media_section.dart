// lib/features/posts/presentation/widgets/post_media_section.dart
import 'dart:io';
import 'package:admin_dashboard/features/posts/presentation/widgets/audio_recorder_widget.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'media_upload_card.dart';

class PostMediaSection extends StatelessWidget {
  final File? thumbnailFile;
  final String? thumbnailUrl;
  final File? videoFile;
  final String? videoUrl;
  final File? audioFile;
  final String? audioUrl;
  final Function(File) onThumbnailPicked;
  final Function(String) onThumbnailUrlSet;
  final VoidCallback onThumbnailCleared;
  final Function(File) onVideoPicked;
  final Function(String) onVideoUrlSet;
  final VoidCallback onVideoCleared;
  final Function(File) onAudioPicked;
  final Function(String) onAudioUrlSet;
  final VoidCallback onAudioCleared;
  final bool isUploadingThumbnail;
  final bool isUploadingVideo;
  final bool isUploadingAudio;
  final double thumbnailProgress;
  final double videoProgress;
  final double audioProgress;

  const PostMediaSection({
    super.key,
    required this.thumbnailFile,
    required this.thumbnailUrl,
    required this.videoFile,
    required this.videoUrl,
    required this.audioFile,
    required this.audioUrl,
    required this.onThumbnailPicked,
    required this.onThumbnailUrlSet,
    required this.onThumbnailCleared,
    required this.onVideoPicked,
    required this.onVideoUrlSet,
    required this.onVideoCleared,
    required this.onAudioPicked,
    required this.onAudioUrlSet,
    required this.onAudioCleared,
    required this.isUploadingThumbnail,
    required this.isUploadingVideo,
    required this.isUploadingAudio,
    required this.thumbnailProgress,
    required this.videoProgress,
    required this.audioProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'الوسائط',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        MediaUploadCard(
          title: 'الصورة المصغرة',
          icon: Icons.image,
          color: Colors.blue,
          file: thumbnailFile,
          url: thumbnailUrl,
          isImage: true,
          isUploading: isUploadingThumbnail,
          progress: thumbnailProgress,
          onFilePick: onThumbnailPicked,
          onUrlSubmit: onThumbnailUrlSet,
          onClear: onThumbnailCleared,
        ),
        const SizedBox(height: 16),
        MediaUploadCard(
          title: 'الفيديو',
          icon: Icons.videocam,
          color: Colors.purple,
          file: videoFile,
          url: videoUrl,
          isImage: false,
          isUploading: isUploadingVideo,
          progress: videoProgress,
          onFilePick: onVideoPicked,
          onUrlSubmit: onVideoUrlSet,
          onClear: onVideoCleared,
        ),
        _buildVideoLinkHint(),
        const SizedBox(height: 16),
        if (audioFile != null || audioUrl != null || true)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AudioRecorderWidget(
              existingFile: audioFile,
              existingUrl: audioUrl,
              onAudioChanged: (file, url) {
                if (file != null) {
                  onAudioPicked(file);
                }
                if (url != null && url.isNotEmpty) {
                  onAudioUrlSet(url);
                }
              },
              isUploading: isUploadingAudio,
              uploadProgress: audioProgress,
            ),
          ),
      ],
    );
  }

  /// ✅ يدعم الآن السيرفر روابط فيديو خارجية (يوتيوب / فيميو / فيسبوك /
  /// غوغل درايف) عبر جدول media بدل حقل video_url القديم. هذا العنصر
  /// يعرض للمستخدم أي مزوّد تم اكتشافه من الرابط المُدخل، أو تنبيهاً
  /// إذا الرابط غير مدعوم، بالإضافة إلى توضيح المزوّدات المسموحة.
  /// ملاحظة: يوتيوب وغوغل درايف يُشغَّلان داخل التطبيق مباشرة عند
  /// عرض المنشور؛ أما فيسبوك وفيميو فتتم محاولة تضمينهما داخلياً مع
  /// فتح خارجي تلقائي عند تعذّر ذلك.
  Widget _buildVideoLinkHint() {
    if (videoFile != null) {
      // فيديو مرفوع كملف: لا حاجة لأي تلميح عن روابط خارجية
      return const SizedBox.shrink();
    }

    final url = videoUrl;
    if (url == null || url.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Text(
          'يمكنك رفع ملف فيديو مباشرة، أو لصق رابط من يوتيوب / غوغل '
          'درايف / فيميو / فيسبوك',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    final provider = detectVideoProvider(url);

    if (provider == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'هذا الرابط قد لا يكون مدعوماً للتشغيل داخل التطبيق. '
                'المزوّدات المدعومة حالياً: يوتيوب، غوغل درايف، فيميو، '
                'وفيسبوك (روابط فيديو عامة فقط). سيُحاول التطبيق فتحه '
                'خارجياً عند الحاجة.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    final providerLabel = {
      'youtube': 'يوتيوب',
      'google_drive': 'غوغل درايف',
      'vimeo': 'فيميو',
      'facebook': 'فيسبوك',
    }[provider]!;

    // ✅ يوتيوب وغوغل درايف مضمونا التشغيل داخل التطبيق نفسه
    final playsInApp = provider == 'youtube' || provider == 'google_drive';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              playsInApp
                  ? 'رابط خارجي من $providerLabel — سيُشغَّل مباشرة داخل التطبيق'
                  : 'رابط خارجي من $providerLabel — سيُحفظ كفيديو خارجي وسيتم '
                      'محاولة تشغيله داخل التطبيق، وفتحه خارجياً إن تعذّر ذلك',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// يكتشف مزوّد الفيديو من الرابط (تقريبي، من جانب الواجهة فقط للعرض).
  /// التحقق الفعلي والملزم يتم من الخادم عند الحفظ (قد يرفض بـ 422).
  static String? detectVideoProvider(String url) {
    final u = url.trim().toLowerCase();
    if (u.contains('youtube.com') || u.contains('youtu.be')) {
      return 'youtube';
    }
    if (u.contains('drive.google.com') || u.contains('docs.google.com/uc')) {
      return 'google_drive';
    }
    if (u.contains('vimeo.com')) {
      return 'vimeo';
    }
    if (u.contains('facebook.com') || u.contains('fb.watch')) {
      return 'facebook';
    }
    return null;
  }
}
