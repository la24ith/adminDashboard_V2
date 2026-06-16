// lib/features/posts/presentation/pages/post_details_page.dart
import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _videoReady = false;
  bool _isVideoPlaying = false;
  bool _isAudioPlaying = false;
  bool _isSeeking = false;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  String? _videoError;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.post.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      final url = ApiConstants.mediaUrl(videoUrl);
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
        _videoDuration = controller.value.duration;
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
        _isVideoPlaying = controller.value.isPlaying;
        _videoPosition = controller.value.position;
      });
    }
  }

  Future<void> _initAudio(String url) async {
    if (_audioPlayer != null && _currentAudioUrl == url) return;

    _currentAudioUrl = url;
    await _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();

    try {
      await _audioPlayer!.setUrl(url);

      _audioDuration = _audioPlayer!.duration ?? Duration.zero;

      _audioPlayer!.positionStream.listen((position) {
        if (mounted) {
          setState(() => _audioPosition = position);
        }
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() => _isAudioPlaying = state.playing);
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _audioPlayer?.dispose();
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
                    if (_getAudioUrl() != null) ...[
                      const SizedBox(height: 18),
                      _buildAudioSection(),
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

  String? _getAudioUrl() {
    // ✅ التحقق من audioUrl مباشرة
    if (widget.post.audioUrl != null && widget.post.audioUrl!.isNotEmpty) {
      return ApiConstants.mediaUrl(widget.post.audioUrl!);
    }
    // ✅ التحقق من media array (بدون casting خاطئ)
    try {
      final audioMedia = widget.post.media.firstWhere((m) => m.isAudio);
      return ApiConstants.mediaUrl(audioMedia.filePath);
    } catch (e) {
      // لا يوجد ملف صوتي في media array
      return null;
    }
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
                      imageUrl: ApiConstants.mediaUrl(widget.post.thumbnail!),
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
            const Text('فيديو مرفق',
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
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _initVideo,
                              child: const Text('إعادة المحاولة'),
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
                      if (!_isVideoPlaying)
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
                            value: _videoDuration.inMilliseconds == 0
                                ? 0
                                : _videoPosition.inMilliseconds.clamp(
                                        0, _videoDuration.inMilliseconds) /
                                    _videoDuration.inMilliseconds,
                            onChanged: (value) {
                              final target = Duration(
                                milliseconds:
                                    (_videoDuration.inMilliseconds * value)
                                        .round(),
                              );
                              setState(() => _videoPosition = target);
                            },
                            onChangeEnd: (value) async {
                              final target = Duration(
                                milliseconds:
                                    (_videoDuration.inMilliseconds * value)
                                        .round(),
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
                            Text(_formatDuration(_videoPosition),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const Spacer(),
                            Text(_formatDuration(_videoDuration),
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
    final audioUrl = _getAudioUrl();
    if (audioUrl == null) return const SizedBox.shrink();

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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.audiotrack_rounded,
                color: AppColors.primary, size: 28),
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
                if (_audioDuration.inSeconds > 0)
                  Text(_formatDuration(_audioDuration),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleAudio(audioUrl),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVideo() {
    if (_videoController == null) return;
    _isVideoPlaying ? _videoController!.pause() : _videoController!.play();
  }

  void _toggleAudio(String url) async {
    await _initAudio(url);

    if (_audioPlayer == null) return;

    if (_isAudioPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play();
    }
  }

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getFileNameFromUrl(String url) {
    return url.split('/').last;
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
}
