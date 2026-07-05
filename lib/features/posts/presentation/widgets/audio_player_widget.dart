// lib/features/post_details/presentation/widgets/premium_audio_player.dart

import 'dart:io';
import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PremiumAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String title;

  const PremiumAudioPlayer({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  @override
  State<PremiumAudioPlayer> createState() => _PremiumAudioPlayerState();
}

class _PremiumAudioPlayerState extends State<PremiumAudioPlayer>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  late AnimationController _waveAnimationController;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);

      _audioPlayer.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      });
      _audioPlayer.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
          _waveAnimationController.stop();
        }
      });
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });

      final localPath = await _downloadWithAuthHeaders(widget.audioUrl);
      if (!mounted) return;

      await _audioPlayer.setSource(DeviceFileSource(localPath));
      debugPrint('✅ Audio loaded from: $localPath');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Audio init error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          // ✅ إصلاح: نعرض سبب الفشل الفعلي للمستخدم (مثلاً "انتهت
          // صلاحية الجلسة" أو "HTTP 404") بدل رسالة عامة غير مفيدة.
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<String> _downloadWithAuthHeaders(String url) async {
    final dir = await getTemporaryDirectory();
    // ✅ إصلاح: نفس مشكلة post_details_page — نعتمد على مسار الرابط
    // فقط (بدون query params كـ expires/signature) كمفتاح كاش ثابت،
    // بدل hash الرابط الكامل الذي يتغيّر مع كل توليد رابط موقّع جديد.
    final stablePath = Uri.tryParse(url)?.path ?? url;
    final cacheFile =
        File('${dir.path}/audio_${stablePath.hashCode.abs()}.mp3');

    if (await cacheFile.exists()) {
      final size = await cacheFile.length();
      // ✅ إصلاح جوهري: قبل هذا الإصلاح كان أي ملف كاش موجود يُستخدم
      // مباشرة بلا أي تحقق من محتواه — وبما أن الخطأ السابق (التوكن
      // الفاسد) كان يخزّن استجابة خطأ JSON/HTML كملف ".mp3" فعلياً،
      // كان هذا الملف الفاسد يُعاد استخدامه إلى الأبد حتى بعد إصلاح
      // التوكن، لأن الكاش "موجود" ولو كان فاسداً! رسائل الخطأ عادة
      // أصغر من 2KB بينما أي ملف صوتي حقيقي أكبر من ذلك بكثير.
      if (size > 2048) {
        debugPrint('✅ Using cached audio: ${cacheFile.path} ($size bytes)');
        return cacheFile.path;
      }
      debugPrint(
          '🗑️ حذف كاش صوتي فاسد/مشبوه (حجمه $size بايت فقط) وإعادة التحميل');
      await cacheFile.delete();
    }

    // ✅ الإصلاح الأساسي والحرج: كان الكود القديم يكتب حرفياً
    // 'Bearer $AuthService.getToken()' — وهذا لا يستدعي الدالة إطلاقاً
    // (صيغة الاستيفاء البسيطة $ في Dart لا تدعم استدعاء دوال بأقواس
    // بدون أقواس معقوفة ${...})، بل يحوّل مرجع الدالة نفسها (tear-off)
    // إلى نص عبر toString()، فيصبح الهيدر شيئاً مثل:
    // "Bearer Closure: () => Future<String?> from Function 'getToken': static.()"
    // وهو ليس توكناً صالحاً بأي شكل، فيرفضه السيرفر دائماً بـ 401.
    // الإصلاح: استدعاء الدالة فعلياً وانتظار نتيجتها أولاً.
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('انتهت صلاحية الجلسة، الرجاء تسجيل الدخول من جديد');
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };
    debugPrint('⬇️ Downloading audio from: ${ApiConstants.mediaUrl(url)}');

    final response = await http
        .get(Uri.parse(ApiConstants.mediaUrl(url)), headers: headers)
        .timeout(const Duration(seconds: 60));

    debugPrint('📥 Status: ${response.statusCode}');
    debugPrint('📥 Content-Type: ${response.headers['content-type']}');
    debugPrint('📥 Content-Length: ${response.headers['content-length']}');

    if (response.statusCode == 200) {
      // ✅ حماية إضافية: حتى مع توكن صحيح، نتحقق أن الاستجابة فعلاً
      // ملف صوتي وليست صفحة خطأ HTML/JSON بريئة الشكل (بعض السيرفرات
      // ترجع 200 مع صفحة خطأ بدل رمز خطأ صريح).
      final contentType = response.headers['content-type'] ?? '';
      final looksLikeError = contentType.contains('json') ||
          contentType.contains('html') ||
          response.bodyBytes.length < 2048;
      if (looksLikeError) {
        throw Exception(
          'الاستجابة ليست ملفاً صوتياً صالحاً (نوع المحتوى: $contentType)',
        );
      }

      await cacheFile.writeAsBytes(response.bodyBytes);
      debugPrint(
          '✅ Saved: ${cacheFile.path} (${response.bodyBytes.length} bytes)');
      return cacheFile.path;
    } else {
      debugPrint('❌ Response body: ${response.body}');
      throw Exception('فشل تحميل الملف الصوتي (HTTP ${response.statusCode})');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_hasError) {
      await _initAudio();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _waveAnimationController.stop();
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }
        await _audioPlayer.resume();
        _waveAnimationController.repeat(reverse: true);
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('❌ Toggle error: $e');
      await _initAudio();
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('❌ Seek error: $e');
    }
  }

  Future<void> _changeSpeed() async {
    setState(() => _playbackSpeed = _playbackSpeed == 1.0 ? 1.5 : 1.0);
    await _audioPlayer.setPlaybackRate(_playbackSpeed);
    HapticFeedback.selectionClick();
  }

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlayPause,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _hasError
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_hasError ? Colors.red : Colors.teal)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Icon(
                            _hasError
                                ? Icons.refresh
                                : (_isPlaying ? Icons.pause : Icons.play_arrow),
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoading
                            ? 'جاري التحميل...'
                            : _hasError
                                ? (_errorMessage ??
                                    'فشل التحميل، اضغط للمحاولة')
                                : 'بودكاست',
                        style: TextStyle(
                          fontSize: 12,
                          color: _hasError
                              ? Colors.red.shade400
                              : (isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.5)),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!_isLoading && !_hasError)
                  GestureDetector(
                    onTap: _changeSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isPlaying)
              AnimatedBuilder(
                animation: _waveAnimationController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      20,
                      (index) => Container(
                        width: 2,
                        height: 10 +
                            (_waveAnimationController.value * 15) *
                                (index % 3 + 1),
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (!_isLoading && !_hasError)
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: (_duration.inSeconds > 0)
                          ? _position.inSeconds
                              .toDouble()
                              .clamp(0, _duration.inSeconds.toDouble())
                          : 0.0,
                      max: _duration.inSeconds > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: _duration.inSeconds > 0
                          ? (value) => _seekTo(Duration(seconds: value.toInt()))
                          : null,
                      activeColor: Colors.teal,
                      inactiveColor: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
