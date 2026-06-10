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
        const SizedBox(height: 16),
        if (audioFile != null || audioUrl != null || true)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: AudioRecorderWidget(
              existingFile: audioFile,
              existingUrl: audioUrl,
              onAudioChanged: (file, url) {
                onAudioPicked(file!);
                if (url != null) onAudioUrlSet(url);
              },
              isUploading: isUploadingAudio,
              uploadProgress: audioProgress,
            ),
          ),
      ],
    );
  }
}
