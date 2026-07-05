// lib/features/post_details/presentation/widgets/premium_video_player.dart
//
// ✅ مشغّل فيديو احترافي كامل المزايا:
// - شريط تقدّم (Scrubber) مع عرض الجزء المُخزَّن مؤقتاً (buffered)
// - عرض الوقت الحالي/الإجمالي
// - تشغيل/إيقاف مؤقت مع أزرار تقديم/ترجيع 10 ثوانٍ
// - سحب سريع بالنقر المزدوج يمين/يسار الشاشة (±10 ثوانٍ) مع مؤشر بصري
// - سرعة تشغيل موسّعة (0.25x → 3x) عبر قائمة سفلية أنيقة (Bottom Sheet)
// - "اضغط مطوّلاً" لتسريع مؤقت 2x أثناء الضغط (مثل نتفليكس/تيك توك)
// - كتم/إلغاء كتم الصوت
// - مؤشر تحميل أثناء الـ buffering
// - إخفاء تلقائي لعناصر التحكم أثناء التشغيل، وإظهارها بلمسة واحدة
// - وضع ملء الشاشة الكامل (تدوير أفقي) بنفس مزايا المشغّل المصغّر
//   بالضبط (سرعة، كتم، سحب سريع بالنقر المزدوج، تسريع مؤقت بالضغط
//   المطوّل)، ويشارك نفس الـ VideoPlayerController فلا ينقطع التشغيل
//   عند الدخول/الخروج من ملء الشاشة، وتُطبَّق أي تغييرات (سرعة/كتم)
//   تمّت داخل ملء الشاشة على المشغّل المصغّر تلقائياً عند الرجوع.
// - حالة تحميل + حالة خطأ مع زر إعادة محاولة، ورسالة خطأ أوضح عند
//   فشل تحميل التوكن (بدل إرسال "Bearer null" بصمت للسيرفر).

import 'dart:async';
import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// سرعات التشغيل المتاحة في كل مكان (مشغّل مصغّر وملء الشاشة).
const List<double> _kPlaybackSpeeds = [
  0.25,
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
  2.5,
  3.0
];

/// قائمة سرعة التشغيل السفلية المشتركة بين المشغّل المصغّر وملء الشاشة.
Future<void> _showSpeedSheet(
  BuildContext context,
  double currentSpeed,
  ValueChanged<double> onSelected,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey.shade900,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'سرعة التشغيل',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            ..._kPlaybackSpeeds.map((s) {
              final isSelected = s == currentSpeed;
              return ListTile(
                dense: true,
                title: Text(
                  s == 1.0 ? '1x (طبيعي)' : '${s}x',
                  style: TextStyle(
                    color: isSelected ? Colors.tealAccent : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.tealAccent)
                    : null,
                onTap: () {
                  onSelected(s);
                  Navigator.pop(sheetContext);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

class PremiumVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const PremiumVideoPlayer({super.key, required this.videoUrl, this.title});

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _errorMessage;

  bool _showControls = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _isMuted = false;

  bool _showSeekFeedback = false;
  bool _seekFeedbackForward = true;

  bool _isHoldFastForwarding = false;
  double _speedBeforeHold = 1.0;

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

    // ✅ إصلاح: كان التوكن يُدرج مباشرة داخل الهيدر حتى لو كان null
    // (يصبح حرفياً السلسلة النصية "Bearer null")، فيرفضه السيرفر بـ 401،
    // ويترجم ExoPlayer هذا الرفض (استجابة HTML/JSON بدل ملف وسائط) إلى
    // خطأ عام "Source error" لا يوضح السبب الحقيقي. الآن نتحقق أولاً
    // ونعرض رسالة واضحة بدل محاولة تشغيل حتمية الفشل.
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'انتهت صلاحية الجلسة، الرجاء تسجيل الدخول من جديد لعرض الفيديو';
      });
      return;
    }

    String videoUrl = widget.videoUrl;
    videoUrl = videoUrl.replaceFirst('http://', 'https://');
    final resolvedUrl = ApiConstants.mediaUrl(videoUrl);

    debugPrint('🎬 [PremiumVideoPlayer] URL = $resolvedUrl');

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(resolvedUrl),
        httpHeaders: {
          'Authorization': 'Bearer $token',
          // ✅ إصلاح: حذفنا هيدر 'Range': 'bytes=0-' اليدوي. ExoPlayer
          // يدير الـ Range تلقائياً بنفسه؛ إرساله يدوياً بقيمة ثابتة
          // "bytes=0-" يتعارض أحياناً مع كيفية تعامل بعض السيرفرات/الـ
          // CDN مع طلبات الـ Range المتكررة أثناء seek/buffering،
          // وقد يُرجع استجابة غير متوقعة يفشل ExoPlayer بقراءتها
          // ("Source error" العام بدون أي تفاصيل إضافية).
        },
      );

      await _controller!.initialize();
      _controller!.addListener(_onControllerUpdate);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [PremiumVideoPlayer] Video error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'فشل تحميل الفيديو، تحقق من اتصالك وحاول مجدداً';
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted && _controller != null && _controller!.value.isInitialized) {
      // ✅ إصلاح: نلتقط أخطاء التشغيل التي تحدث بعد التهيئة الناجحة
      // (مثل انقطاع الستريم أثناء التشغيل) بدل تجاهلها بصمت — كانت
      // الشاشة تتجمّد بدون أي مؤشر أو رسالة عند حدوث خطأ لاحق كهذا.
      final err = _controller!.value.errorDescription;
      if (err != null && _errorMessage == null) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تشغيل الفيديو';
        });
        return;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  // ==================== تحكّم بالتشغيل ====================

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
      _hideControlsTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      controller.play();
      _startHideControlsTimer();
    }
    setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
    if (_showControls && (_controller?.value.isPlaying ?? false)) {
      _startHideControlsTimer();
    }
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > controller.value.duration
            ? controller.value.duration
            : target);
    await controller.seekTo(clamped);
  }

  void _handleDoubleTap(bool forward) {
    _seekRelative(Duration(seconds: forward ? 10 : -10));
    setState(() {
      _showSeekFeedback = true;
      _seekFeedbackForward = forward;
    });
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSeekFeedback = false);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _changeSpeed(double speed) async {
    setState(() => _playbackSpeed = speed);
    await _controller?.setPlaybackSpeed(speed);
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _controller?.setVolume(_isMuted ? 0 : 1);
  }

  void _startHoldFastForward() {
    if (_controller == null || !_controller!.value.isPlaying) return;
    _speedBeforeHold = _playbackSpeed;
    setState(() => _isHoldFastForwarding = true);
    _controller!.setPlaybackSpeed(2.0);
    HapticFeedback.mediumImpact();
  }

  void _endHoldFastForward() {
    if (!_isHoldFastForwarding) return;
    setState(() => _isHoldFastForwarding = false);
    _controller?.setPlaybackSpeed(_speedBeforeHold);
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null) return;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!mounted) return;
    final result = await Navigator.of(context).push<_PlaybackSettings>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(
          controller: controller,
          title: widget.title,
          initialSpeed: _playbackSpeed,
          initialMuted: _isMuted,
        ),
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted && result != null) {
      setState(() {
        _playbackSpeed = result.speed;
        _isMuted = result.muted;
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    if (_controller == null || !_isInitialized) {
      return Container(color: Colors.black, height: 250);
    }

    final controller = _controller!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: GestureDetector(
          onTap: _toggleControlsVisibility,
          onDoubleTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final tapX = details.localPosition.dx;
            final isRightSide = tapX > box.size.width / 2;
            _handleDoubleTap(isRightSide);
          },
          onLongPressStart: (_) => _startHoldFastForward(),
          onLongPressEnd: (_) => _endHoldFastForward(),
          onLongPressCancel: _endHoldFastForward,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              if (controller.value.isBuffering && !_isHoldFastForwarding)
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              if (_showSeekFeedback)
                Align(
                  alignment: _seekFeedbackForward
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _seekFeedbackForward
                            ? Icons.forward_10_rounded
                            : Icons.replay_10_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              if (_isHoldFastForwarding)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_forward_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('2x',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildBottomControls(
                      controller: controller,
                      speed: _playbackSpeed,
                      isMuted: _isMuted,
                      onSpeedTap: () => _showSpeedSheet(
                          context, _playbackSpeed, _changeSpeed),
                      onMuteTap: _toggleMute,
                      onFullscreenTap: _openFullscreen,
                      onSeekBack: () => _handleDoubleTap(false),
                      onSeekForward: () => _handleDoubleTap(true),
                      onScrubStart: () => _hideControlsTimer?.cancel(),
                      onScrubEnd: () {
                        if (controller.value.isPlaying) {
                          _startHideControlsTimer();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.black,
        height: 250,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.tealAccent),
              SizedBox(height: 12),
              Text('جاري تحميل الفيديو...',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.grey[900],
        height: 250,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 44),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeVideo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نتيجة تُعاد من صفحة ملء الشاشة عند الرجوع، لتطبيق أي تغيير بالسرعة
/// أو الكتم تمّ داخل ملء الشاشة على المشغّل المصغّر أيضاً.
class _PlaybackSettings {
  final double speed;
  final bool muted;
  const _PlaybackSettings(this.speed, this.muted);
}

/// ✅ شريط التحكّم السفلي المشترك بين المشغّل المصغّر وملء الشاشة —
/// نفس الشكل والمزايا بالضبط في الحالتين (اتساق كامل بين الوضعين).
Widget _buildBottomControls({
  required VideoPlayerController controller,
  required double speed,
  required bool isMuted,
  required VoidCallback onSpeedTap,
  required VoidCallback onMuteTap,
  VoidCallback? onFullscreenTap,
  required VoidCallback onSeekBack,
  required VoidCallback onSeekForward,
  required VoidCallback onScrubStart,
  required VoidCallback onScrubEnd,
}) {
  final position = controller.value.position;
  final duration = controller.value.duration;
  final buffered = controller.value.buffered.isNotEmpty
      ? controller.value.buffered.last.end
      : Duration.zero;

  return StatefulBuilder(
    builder: (context, setLocalState) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 24, 6, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: SliderComponentShape.noThumb,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: duration.inMilliseconds == 0
                          ? 0
                          : buffered.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: null,
                      activeColor: Colors.white.withOpacity(0.45),
                      inactiveColor: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: duration.inMilliseconds == 0
                          ? 0
                          : position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1,
                      onChangeStart: (_) => onScrubStart(),
                      onChanged: (v) {
                        controller.seekTo(Duration(milliseconds: v.round()));
                        setLocalState(() {});
                      },
                      onChangeEnd: (_) => onScrubEnd(),
                      activeColor: Colors.tealAccent.shade400,
                      inactiveColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 6),
                Text(
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white, fontSize: 11.5),
                ),
                const Text(' / ',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5)),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onSeekBack,
                  icon: const Icon(Icons.replay_10_rounded,
                      color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: onSeekForward,
                  icon: const Icon(Icons.forward_10_rounded,
                      color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onSpeedTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${speed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: onMuteTap,
                  icon: Icon(
                    isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                if (onFullscreenTap != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: onFullscreenTap,
                    icon: const Icon(Icons.fullscreen_rounded,
                        color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// صفحة ملء الشاشة (تدوير أفقي) — تشارك نفس الـ VideoPlayerController
/// الأصلي بدل إعادة تحميل الفيديو من جديد، وتحتوي على **كل** مزايا
/// المشغّل المصغّر (سرعة، كتم، سحب سريع بالنقر المزدوج، تسريع مؤقت
/// بالضغط المطوّل) لضمان تجربة متكاملة في ملء الشاشة، لا نسخة منقوصة.
class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final String? title;
  final double initialSpeed;
  final bool initialMuted;

  const _FullscreenVideoPage({
    required this.controller,
    required this.initialSpeed,
    required this.initialMuted,
    this.title,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  bool _showControls = true;
  Timer? _hideTimer;
  late double _speed = widget.initialSpeed;
  late bool _isMuted = widget.initialMuted;

  bool _showSeekFeedback = false;
  bool _seekFeedbackForward = true;

  bool _isHoldFastForwarding = false;
  double _speedBeforeHold = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
    _startHideTimer();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && widget.controller.value.isPlaying) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      _hideTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      widget.controller.play();
      _startHideTimer();
    }
    setState(() {});
  }

  Future<void> _seekRelative(Duration offset) async {
    final target = widget.controller.value.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > widget.controller.value.duration
            ? widget.controller.value.duration
            : target);
    await widget.controller.seekTo(clamped);
  }

  void _handleDoubleTap(bool forward) {
    _seekRelative(Duration(seconds: forward ? 10 : -10));
    setState(() {
      _showSeekFeedback = true;
      _seekFeedbackForward = forward;
    });
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSeekFeedback = false);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _changeSpeed(double speed) async {
    setState(() => _speed = speed);
    await widget.controller.setPlaybackSpeed(speed);
  }

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await widget.controller.setVolume(_isMuted ? 0 : 1);
  }

  void _startHoldFastForward() {
    if (!widget.controller.value.isPlaying) return;
    _speedBeforeHold = _speed;
    setState(() => _isHoldFastForwarding = true);
    widget.controller.setPlaybackSpeed(2.0);
    HapticFeedback.mediumImpact();
  }

  void _endHoldFastForward() {
    if (!_isHoldFastForwarding) return;
    setState(() => _isHoldFastForwarding = false);
    widget.controller.setPlaybackSpeed(_speedBeforeHold);
  }

  void _pop() {
    Navigator.of(context).pop(_PlaybackSettings(_speed, _isMuted));
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, resultAlreadyPopped) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final isRightSide = details.localPosition.dx > box.size.width / 2;
            _handleDoubleTap(isRightSide);
          },
          onLongPressStart: (_) => _startHoldFastForward(),
          onLongPressEnd: (_) => _endHoldFastForward(),
          onLongPressCancel: _endHoldFastForward,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio == 0
                      ? 16 / 9
                      : controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              if (controller.value.isBuffering && !_isHoldFastForwarding)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              if (_showSeekFeedback)
                Align(
                  alignment: _seekFeedbackForward
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _seekFeedbackForward
                            ? Icons.forward_10_rounded
                            : Icons.replay_10_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              if (_isHoldFastForwarding)
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fast_forward_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('2x',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _pop,
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              if (widget.title != null &&
                                  widget.title!.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    widget.title!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildBottomControls(
                          controller: controller,
                          speed: _speed,
                          isMuted: _isMuted,
                          onSpeedTap: () =>
                              _showSpeedSheet(context, _speed, _changeSpeed),
                          onMuteTap: _toggleMute,
                          onFullscreenTap: null,
                          onSeekBack: () => _handleDoubleTap(false),
                          onSeekForward: () => _handleDoubleTap(true),
                          onScrubStart: () => _hideTimer?.cancel(),
                          onScrubEnd: () {
                            if (controller.value.isPlaying) {
                              _startHideTimer();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
