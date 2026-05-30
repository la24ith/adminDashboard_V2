// lib/features/posts/presentation/widgets/media_upload_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import 'media_preview_card.dart';

class MediaUploadCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final File? file;
  final String? url;
  final bool isImage;
  final bool isUploading;
  final double progress;
  final Function(File) onFilePick;
  final Function(String) onUrlSubmit;
  final VoidCallback onClear;

  const MediaUploadCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.file,
    this.url,
    required this.isImage,
    required this.isUploading,
    required this.progress,
    required this.onFilePick,
    required this.onUrlSubmit,
    required this.onClear,
  });

  @override
  State<MediaUploadCard> createState() => _MediaUploadCardState();
}

class _MediaUploadCardState extends State<MediaUploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia =
        widget.file != null || (widget.url != null && widget.url!.isNotEmpty);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, size: 22, color: widget.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasMedia ? 'ملف مرفق' : 'لم يتم إرفاق ملف',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasMedia ? widget.color : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasMedia && !widget.isUploading)
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: Colors.red.shade400),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.isUploading) _buildUploadProgress(),
          if (!widget.isUploading && hasMedia)
            MediaPreviewCard(
              file: widget.file,
              url: widget.url,
              isImage: widget.isImage,
              icon: widget.icon,
              color: widget.color,
            ),
          if (!widget.isUploading && !hasMedia) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'جاري الرفع ${(widget.progress * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 13,
                    color: widget.color,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              onEnter: (_) => _hoverController.forward(),
              onExit: (_) => _hoverController.reverse(),
              child: AnimatedBuilder(
                animation: _hoverController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_hoverController.value * 0.02),
                    child: OutlinedButton.icon(
                      onPressed: () => _pickFile(),
                      icon: Icon(Icons.cloud_upload,
                          size: 18, color: widget.color),
                      label: const Text('رفع ملف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: widget.color.withOpacity(0.5)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showUrlDialog(),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('إدخال رابط'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    if (widget.isImage) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _validateFileSize(File(picked.path),
            maxMB: ApiConstants.maxImageSizeMB);
        widget.onFilePick(File(picked.path));
      }
    } else if (widget.title == 'الفيديو') {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null) {
        _validateFileSize(File(result.files.single.path!),
            maxMB: ApiConstants.maxVideoSizeMB);
        widget.onFilePick(File(result.files.single.path!));
      }
    } else {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null) {
        _validateFileSize(File(result.files.single.path!),
            maxMB: ApiConstants.maxAudioSizeMB);
        widget.onFilePick(File(result.files.single.path!));
      }
    }
  }

  void _validateFileSize(File file, {required int maxMB}) {
    final sizeInMB = file.lengthSync() / (1024 * 1024);
    if (sizeInMB > maxMB && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ حجم الملف كبير جداً (${sizeInMB.toStringAsFixed(1)} MB). الحد الأقصى $maxMB MB'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showUrlDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('رابط ${widget.title}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onUrlSubmit(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
