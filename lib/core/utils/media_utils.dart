// lib/core/utils/media_utils.dart
import 'dart:io';

import 'package:video_compress/video_compress.dart';

class MediaUtils {
  // ضغط الفيديو
  static Future<File?> compressVideo(File videoFile, {int quality = 50}) async {
    try {
      // ضغط الفيديو
      final info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: VideoQuality.LowQuality, // MediumQuality, HighQuality
        deleteOrigin: false, // لا تحذف الملف الأصلي
        includeAudio: true, // احتفظ بالصوت
        frameRate: 24, // معدل الإطارات
      );

      if (info != null && info.file != null) {
        final compressedSize = await info.file!.length();
        final originalSize = await videoFile.length();
        print(
            '📹 Original: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print(
            '📹 Compressed: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        return File(info.file!.path);
      }
      return videoFile;
    } catch (e) {
      print('⚠️ Video compress error: $e');
      return videoFile;
    }
  }

  // الحصول على حجم الملف
  static String getFileSize(File file) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    return '${sizeInMB.toStringAsFixed(2)} MB';
  }
}
