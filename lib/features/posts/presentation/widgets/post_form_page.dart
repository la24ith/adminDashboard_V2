// lib/features/posts/presentation/widgets/post_form_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/post_model.dart';
import '../state/posts_controller.dart';
import 'post_header_section.dart';
import 'post_basic_info_section.dart';
import 'post_media_section.dart';
import 'post_schedule_section.dart';
import 'post_save_bar.dart';

class PostFormPage extends StatefulWidget {
  final Post? post;
  final PostsController controller;

  const PostFormPage({super.key, this.post, required this.controller});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late PostStatus _status;
  DateTime? _scheduledDate;
  bool _scheduleLater = false;
  bool _isSaving = false;

  // Media files
  File? _thumbnailFile;
  String? _thumbnailUrl;
  File? _videoFile;
  String? _videoUrl;
  File? _audioFile;
  String? _audioUrl;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _titleController = TextEditingController(text: post?.title ?? '');
    _contentController = TextEditingController(text: post?.content ?? '');
    _status = post?.status ?? PostStatus.draft;
    _scheduledDate = post?.scheduledFor;
    _scheduleLater = _status == PostStatus.scheduled;
    _thumbnailUrl = post?.thumbnail;
    _videoUrl = post?.videoUrl;
    _audioUrl = post?.audioUrl;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _animationController,
        child: Stack(
          children: [
            CustomScrollView(
              controller: ScrollController(),
              slivers: [
                PostHeaderSection(
                  isEditing: widget.post != null,
                  status: _status,
                  onStatusChanged: (status) => setState(() => _status = status),
                  onCancel: () => Navigator.pop(context),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildErrorWidget(),
                            const SizedBox(height: 8),
                            PostBasicInfoSection(
                              titleController: _titleController,
                              contentController: _contentController,
                            ),
                            const SizedBox(height: 24),
                            PostMediaSection(
                              thumbnailFile: _thumbnailFile,
                              thumbnailUrl: _thumbnailUrl,
                              videoFile: _videoFile,
                              videoUrl: _videoUrl,
                              audioFile: _audioFile,
                              audioUrl: _audioUrl,
                              onThumbnailPicked: (file) =>
                                  setState(() => _thumbnailFile = file),
                              onThumbnailUrlSet: (url) =>
                                  setState(() => _thumbnailUrl = url),
                              onThumbnailCleared: () => setState(() {
                                _thumbnailFile = null;
                                _thumbnailUrl = null;
                              }),
                              onVideoPicked: (file) =>
                                  setState(() => _videoFile = file),
                              onVideoUrlSet: (url) =>
                                  setState(() => _videoUrl = url),
                              onVideoCleared: () => setState(() {
                                _videoFile = null;
                                _videoUrl = null;
                              }),
                              onAudioPicked: (file) =>
                                  setState(() => _audioFile = file),
                              onAudioUrlSet: (url) =>
                                  setState(() => _audioUrl = url),
                              onAudioCleared: () => setState(() {
                                _audioFile = null;
                                _audioUrl = null;
                              }),
                              isUploadingThumbnail: widget.controller
                                  .isUploadingMedia('thumbnail'),
                              isUploadingVideo:
                                  widget.controller.isUploadingMedia('video'),
                              isUploadingAudio:
                                  widget.controller.isUploadingMedia('audio'),
                              thumbnailProgress: widget.controller
                                  .getUploadProgress('thumbnail'),
                              videoProgress:
                                  widget.controller.getUploadProgress('video'),
                              audioProgress:
                                  widget.controller.getUploadProgress('audio'),
                            ),
                            const SizedBox(height: 24),
                            PostScheduleSection(
                              scheduleLater: _scheduleLater,
                              scheduledDate: _scheduledDate,
                              onScheduleChanged: (value) => setState(() {
                                _scheduleLater = value;
                                _status = value
                                    ? PostStatus.scheduled
                                    : PostStatus.draft;
                                if (value && _scheduledDate == null) {
                                  _scheduledDate = DateTime.now()
                                      .add(const Duration(days: 1));
                                }
                              }),
                              onDateSelected: (date) =>
                                  setState(() => _scheduledDate = date),
                            ),
                            const SizedBox(
                                height: 120), // Space for floating button
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PostSaveBar(
                isSaving: _isSaving,
                isUploading: widget.controller.isUploadingMedia('thumbnail') ||
                    widget.controller.isUploadingMedia('video') ||
                    widget.controller.isUploadingMedia('audio'),
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.controller.error == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.error_outline,
                color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.controller.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => widget.controller.clearError(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final isEdit = widget.post != null;
    bool success;

    if (isEdit) {
      success = await widget.controller.updatePost(
        widget.post!.id,
        title: _titleController.text,
        content: _contentController.text,
        status: _status,
        scheduledFor: _scheduleLater ? _scheduledDate : null,
        thumbnailFile: _thumbnailFile,
        thumbnailUrl: _thumbnailUrl,
        videoFile: _videoFile,
        videoUrl: _videoUrl,
        audioFile: _audioFile,
        audioUrl: _audioUrl,
      );
    } else {
      success = await widget.controller.createPost(
        title: _titleController.text,
        content: _contentController.text,
        status: _status,
        scheduledFor: _scheduleLater ? _scheduledDate : null,
        thumbnailFile: _thumbnailFile,
        thumbnailUrl: _thumbnailUrl,
        videoFile: _videoFile,
        videoUrl: _videoUrl,
        audioFile: _audioFile,
        audioUrl: _audioUrl,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('تم حفظ المنشور بنجاح'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _isSaving = false);
    }
  }
}
