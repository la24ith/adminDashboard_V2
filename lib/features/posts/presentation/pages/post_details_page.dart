// lib/features/posts/presentation/pages/post_details_page.dart (النسخة المصححة)
import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _isPlaying = false;
  bool _isSeeking = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final video = widget.post.videoUrl;
    if (video == null || video.isEmpty) {
      setState(() => _videoError = 'لا يوجد فيديو مرفق');
      return;
    }

    try {
      final url = ApiConstants.getFullMediaUrl(video);
      debugPrint('🎬 VIDEO URL = $url');

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();

      controller.addListener(_videoListener);

      if (!mounted) {
        controller.dispose();
        return;
      }

      _videoController = controller;

      setState(() {
        _videoReady = true;
        _duration = controller.value.duration;
        _videoError = null;
      });
    } catch (e) {
      setState(() => _videoError = 'فشل تحميل الفيديو: ${e.toString()}');
    }
  }

  void _videoListener() {
    final controller = _videoController;
    if (!mounted || controller == null) return;

    if (!_isSeeking) {
      setState(() {
        _isPlaying = controller.value.isPlaying;
        _position = controller.value.position;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMeta(),
                    const SizedBox(height: 18),
                    _buildTitle(),
                    const SizedBox(height: 20),
                    _buildContent(),
                    if (widget.post.hasVideo) ...[
                      const SizedBox(height: 26),
                      _buildVideoSection(),
                    ],
                    if (widget.post.hasAudio) ...[
                      const SizedBox(height: 18),
                      _buildAudioSection(),
                    ],
                    // تعديل这部分 - استخدام hasVideo أو hasImages بناءً على وجود videoUrl
                    if (widget.post.videoUrl == null &&
                        _hasMultipleImages()) ...[
                      const SizedBox(height: 18),
                      _buildImagesSection(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasMultipleImages() {
    // إذا كان لديك قائمة media، استخدمها
    // وإلا استخدم false
    return false;
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      expandedHeight: widget.post.hasThumbnail ? 310 : 130,
      leading: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: widget.post.hasThumbnail
            ? Hero(
                tag: 'post-${widget.post.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl:
                          ApiConstants.getFullMediaUrl(widget.post.thumbnail!),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.accent.withOpacity(.08),
                        child: const Center(
                            child: Icon(Icons.image_not_supported_outlined)),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(.18),
                            Colors.black.withOpacity(.28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                color: AppColors.accent.withOpacity(.08),
                child: Center(
                  child: Icon(Icons.article_outlined,
                      size: 52, color: AppColors.accent),
                ),
              ),
      ),
    );
  }

  Widget _buildMeta() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metaChip(
          icon: _statusIcon(),
          text: widget.post.status.arabicName,
          color: _statusColor(),
        ),
        _metaChip(
          icon: Icons.calendar_today_outlined,
          text: widget.post.displayDate,
          color: Colors.grey.shade700,
          background: Colors.grey.shade100,
        ),
        // تعديل这部分 - إظهار عدد الملفات إذا كان موجوداً
        if (_getMediaCount() > 0)
          _metaChip(
            icon: Icons.attach_file_outlined,
            text: '${_getMediaCount()} ملفات مرفقة',
            color: AppColors.accent,
            background: AppColors.accent.withOpacity(.08),
          ),
      ],
    );
  }

  int _getMediaCount() {
    int count = 0;
    if (widget.post.hasVideo) count++;
    if (widget.post.hasAudio) count++;
    if (widget.post.hasThumbnail) count++;
    return count;
  }

  Widget _metaChip({
    required IconData icon,
    required String text,
    required Color color,
    Color? background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.post.title,
      style: const TextStyle(
          fontSize: 27, fontWeight: FontWeight.w800, height: 1.28),
    );
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child: Text(
        widget.post.content,
        style: TextStyle(
            fontSize: 16.4, height: 1.85, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildVideoSection() {
    final videoUrl = widget.post.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('فيديو مرفق',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),
        _buildVideoCard(),
      ],
    );
  }

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(.10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: !_videoReady
            ? SizedBox(
                height: 230,
                child: Center(
                  child: _videoError != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 32),
                            const SizedBox(height: 8),
                            Text(_videoError!,
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      if (!_isPlaying)
                        GestureDetector(
                          onTap: _toggleVideo,
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 42),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _duration.inMilliseconds == 0
                                ? 0
                                : _position.inMilliseconds
                                        .clamp(0, _duration.inMilliseconds) /
                                    _duration.inMilliseconds,
                            onChanged: (value) {
                              final target = Duration(
                                milliseconds:
                                    (_duration.inMilliseconds * value).round(),
                              );
                              setState(() => _position = target);
                            },
                            onChangeEnd: (value) async {
                              final target = Duration(
                                milliseconds:
                                    (_duration.inMilliseconds * value).round(),
                              );
                              _isSeeking = true;
                              await _videoController?.seekTo(target);
                              _isSeeking = false;
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Text(_formatDuration(_position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const Spacer(),
                            Text(_formatDuration(_duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAudioSection() {
    final audioUrl = widget.post.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 5),
              color: Colors.black.withOpacity(.04)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.audiotrack_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملف صوتي',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(_getFileNameFromUrl(audioUrl),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _playAudio(audioUrl),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    return url.split('/').last;
  }

  Widget _buildImagesSection() {
    // إذا كان لديك قائمة صور، قم بعرضها هنا
    // حالياً نعيد SizedBox فارغاً لأن Post model لا يحتوي على قائمة media
    return const SizedBox.shrink();
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    _isPlaying ? _videoController!.pause() : _videoController!.play();
  }

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _statusColor() {
    switch (widget.post.status) {
      case PostStatus.published:
        return AppColors.success;
      case PostStatus.scheduled:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon() {
    switch (widget.post.status) {
      case PostStatus.published:
        return Icons.check_circle;
      case PostStatus.scheduled:
        return Icons.schedule;
      default:
        return Icons.edit_note;
    }
  }

  void _playAudio(String filePath) {
    final url = ApiConstants.getFullMediaUrl(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تشغيل الصوت: ${url.split('/').last}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
