// lib/features/post_details/presentation/widgets/premium_video_player.dart

import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/di/setup_locator.dart';
import 'package:admin_dashboard/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PremiumVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const PremiumVideoPlayer({super.key, required this.videoUrl});

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // final secureStorage = getIt<SecureStorageService>();
    final token = await AuthService.getToken();
    // final deviceId = await secureStorage.read(key: 'device_id');

    String videoUrl = widget.videoUrl;

    // ngrok يحتاج https
    videoUrl = videoUrl.replaceFirst(
      'http://',
      'https://',
    );

    try {
      // ✅ استخدام networkUrl مباشرة (streaming بدون تحميل كامل)
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(ApiConstants.mediaUrl(videoUrl)),
        httpHeaders: {
          'Authorization': 'Bearer $token',
          //  'X-Device-Id': deviceId ?? '',
          'Range': 'bytes=0-',
        },
      );

      await _controller!.initialize();
      _controller!.addListener(_updatePosition);

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

      print('✅ Video streaming ready');
    } catch (e) {
      print('❌ Video error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل تحميل الفيديو';
      });
    }
  }

  void _updatePosition() {
    if (mounted && _controller != null && _controller!.value.isInitialized) {
      setState(() {});
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Container(
        color: Colors.black,
        height: 250,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 12),
              Text('جاري تحميل الفيديو...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Colors.grey[900],
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initializeVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_isInitialized) {
      return Container(color: Colors.black, height: 250);
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          GestureDetector(
            onTap: _togglePlayPause,
            child: AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
