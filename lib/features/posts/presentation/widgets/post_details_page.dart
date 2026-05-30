// lib/features/posts/presentation/widgets/post_details_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/post_model.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _isPlaying = false;
  bool _isSeeking = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _videoError;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();
  }

  Future<void> _initVideo() async {
    final video = widget.post.firstVideo;
    if (video == null) {
      setState(() => _videoError = 'لا يوجد فيديو مرفق');
      return;
    }

    try {
      final url = ApiConstants.getFullMediaUrl(video.filePath);
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FadeTransition(
          opacity: _animationController,
          child: CustomScrollView(
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
                      const SizedBox(height: 20),
                      _buildTitle(),
                      const SizedBox(height: 24),
                      _buildContent(),
                      if (widget.post.hasVideo) ...[
                        const SizedBox(height: 28),
                        _buildVideoSection(),
                      ],
                      if (widget.post.hasAudio) ...[
                        const SizedBox(height: 20),
                        _buildAudioSection(),
                      ],
                      if (widget.post.hasImages &&
                          widget.post.media.where((m) => m.isImage).length >
                              1) ...[
                        const SizedBox(height: 20),
                        _buildImagesSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      expandedHeight: widget.post.hasThumbnail ? 380 : 160,
      leading: Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.accent.withOpacity(0.08),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined,
                              size: 64),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.article_outlined,
                      size: 72, color: AppColors.accent.withOpacity(0.3)),
                ),
              ),
      ),
    );
  }

  Widget _buildMeta() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metaChip(
          icon: _statusIcon(),
          text: widget.post.status.arabicName,
          color: _statusColor(),
          background: _statusColor().withOpacity(0.1),
        ),
        _metaChip(
          icon: Icons.calendar_today_outlined,
          text: widget.post.displayDate,
          color: Colors.grey.shade700,
          background: Colors.grey.shade100,
        ),
        if (widget.post.media.isNotEmpty)
          _metaChip(
            icon: Icons.attach_file_outlined,
            text:
                '${widget.post.media.length} ${widget.post.media.length == 1 ? 'ملف' : 'ملفات'}',
            color: AppColors.accent,
            background: AppColors.accent.withOpacity(0.08),
          ),
      ],
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String text,
    required Color color,
    Color? background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background ?? color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.post.title,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.3,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Text(
        widget.post.content,
        style: TextStyle(
          fontSize: 16.5,
          height: 1.75,
          color: Colors.grey.shade800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    final video = widget.post.firstVideo;
    if (video == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.videocam, color: Colors.purple, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'فيديو مرفق',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                video.fileSizeFormatted,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildVideoCard(),
      ],
    );
  }

  Widget _buildVideoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: !_videoReady
            ? SizedBox(
                height: 260,
                child: Center(
                  child: _videoError != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.error_outline,
                                  color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _videoError!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 48),
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
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
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
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
    final audio = widget.post.firstAudio;
    if (audio == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withOpacity(0.1),
                  AppColors.accent.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.audiotrack_rounded,
                color: AppColors.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ملف صوتي',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  audio.fileSizeFormatted,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _playAudio(audio.filePath),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    final images = widget.post.media.where((m) => m.isImage).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.photo_library,
                  color: Colors.green, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'معرض الصور',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${images.length} صور',
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final image = images[index];
              return GestureDetector(
                onTap: () => _showFullscreenImage(image.filePath),
                child: Hero(
                  tag: 'gallery-${widget.post.id}-$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.getFullMediaUrl(image.filePath),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 32),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullscreenImage(String filePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: ApiConstants.getFullMediaUrl(filePath),
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.error, size: 48, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        content: Row(
          children: [
            const Icon(Icons.audiotrack, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('تشغيل الصوت: ${url.split('/').last}'),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
