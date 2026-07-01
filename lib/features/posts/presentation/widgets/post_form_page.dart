import 'dart:async';
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
  // ✅ حُذف _isSaving المحلي — نعتمد على controller.isActionInProgress فقط
  String _selectedSegment = 'general';

  // ✅ ScrollController دائم (بدل إنشاء واحد جديد بكل build) لنتمكن من
  // التمرير برمجياً لأعلى عند ظهور خطأ جديد
  final ScrollController _scrollController = ScrollController();

  // لتتبّع آخر رسالة خطأ ومعرفة متى يظهر خطأ "جديد" فعلاً
  String? _lastError;
  Timer? _errorAutoHideTimer;

  // Media files
  File? _thumbnailFile;
  String? _thumbnailUrl;
  File? _videoFile;
  String? _videoUrl;
  File? _audioFile;
  String? _audioUrl;

  late AnimationController _animationController;

  final List<Map<String, dynamic>> _segments = [
    {'value': 'general', 'label': 'عام', 'icon': Icons.public},
    {'value': 'diabetic', 'label': 'مرضى السكري', 'icon': Icons.bloodtype},
    {
      'value': 'breastfeeding',
      'label': 'مرضعات',
      'icon': Icons.family_restroom
    },
    {
      'value': 'weight_loss',
      'label': 'إنقاص الوزن',
      'icon': Icons.fitness_center
    },
    {'value': 'weight_gain', 'label': 'زيادة الوزن', 'icon': Icons.restaurant},
  ];

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
    _selectedSegment = post?.segment ?? 'general';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // ✅ الاستماع للتغييرات في الـ controller لإعادة بناء الـ widget
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final currentError = widget.controller.error;

    // خطأ جديد ظهر (مختلف عن آخر خطأ عرضناه): نمرر لأعلى الشاشة تلقائياً
    // ونشغّل مؤقت إخفاء تلقائي حتى لا يبقى البانر معلقاً للأبد
    if (currentError != null && currentError != _lastError) {
      _scrollToTop();
      _startErrorAutoHideTimer();
    }
    _lastError = currentError;

    setState(() {});
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _startErrorAutoHideTimer() {
    _errorAutoHideTimer?.cancel();
    _errorAutoHideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) widget.controller.clearError();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _errorAutoHideTimer?.cancel();
    _scrollController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ نقرأ حالة الحفظ مباشرة من الـ controller
    final isSaving = widget.controller.isActionInProgress;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _animationController,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
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
                            PostBasicInfoSection(
                              titleController: _titleController,
                              contentController: _contentController,
                            ),
                            const SizedBox(height: 24),
                            _buildSegmentSection(),
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
                            const SizedBox(height: 120),
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
                // ✅ يعتمد مباشرة على controller بدلاً من _isSaving المحلي
                isSaving: isSaving,
                isUploading: widget.controller.isUploadingMedia('thumbnail') ||
                    widget.controller.isUploadingMedia('video') ||
                    widget.controller.isUploadingMedia('audio'),
                onSave: _save,
              ),
            ),
            // ✅ بانر خطأ عائم ثابت أعلى الشاشة: مستقل تماماً عن موضع
            // السكرول، فيظهر فوراً للمستخدم أينما كان في النموذج
            // بدل الحاجة للتمرير لأعلى ليراه.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: widget.controller.error != null
                      ? _buildErrorBanner(widget.controller.error!)
                      : const SizedBox.shrink(key: ValueKey('no-error')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الجمهور المستهدف',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'اختر الفئة المستهدفة للمنشور',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _segments.map((segment) {
                final isSelected = _selectedSegment == segment['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        segment['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        segment['label'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedSegment = segment['value'];
                    });
                  },
                  selectedColor: AppColors.accent,
                  backgroundColor: Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color:
                          isSelected ? AppColors.accent : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  elevation: isSelected ? 2 : 0,
                  shadowColor: AppColors.accent.withOpacity(0.3),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      key: ValueKey(message),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _errorAutoHideTimer?.cancel();
              widget.controller.clearError();
            },
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
    // ✅ نمنع الضغط المزدوج عبر الـ controller مباشرة
    if (widget.controller.isActionInProgress) return;

    final isEdit = widget.post != null;
    bool success;

    if (isEdit) {
      success = await widget.controller.updatePost(
        widget.post!.id,
        title: _titleController.text,
        content: _contentController.text,
        status: _status,
        segment: _selectedSegment,
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
        segment: _selectedSegment,
        // ✅ إصلاح: لا ترسل scheduledFor عند الإنشاء العادي
        scheduledFor: _scheduleLater ? _scheduledDate : null,
        thumbnailFile: _thumbnailFile,
        thumbnailUrl: _thumbnailUrl,
        videoFile: _videoFile,
        videoUrl: _videoUrl,
        audioFile: _audioFile,
        audioUrl: _audioUrl,
      );
    }

    // ✅ التحقق من mounted قبل أي عملية على الـ context
    if (!mounted) return;

    if (success) {
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
    }
    // عند الفشل: الـ controller يضبط _error تلقائياً ويُشعر الـ listener
  }
}
