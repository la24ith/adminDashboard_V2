// lib/features/posts/presentation/widgets/media_preview_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/api_constants.dart';

class MediaPreviewCard extends StatelessWidget {
  final File? file;
  final String? url;
  final bool isImage;
  final IconData icon;
  final Color color;

  const MediaPreviewCard({
    super.key,
    required this.file,
    required this.url,
    required this.isImage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isImage ? _buildImagePreview() : _buildFilePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Hero(
        tag: file?.path ?? url ?? '',
        child: file != null
            ? Image.file(file!, fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: ApiConstants.mediaUrl(url!),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('فشل تحميل الصورة',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName =
        file != null ? file!.path.split('/').last : url!.split('/').last;
    final fileSize =
        file != null ? _formatFileSize(file!.lengthSync()) : 'رابط خارجي';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fileSize,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.insert_drive_file, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
