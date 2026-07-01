// lib/features/posts/presentation/pages/post_details_page.dart
import 'dart:io';
import 'package:admin_dashboard/core/constants/api_constants.dart';
import 'package:admin_dashboard/core/constants/app_colors.dart';
import 'package:admin_dashboard/features/posts/data/models/post_model.dart';
import 'package:admin_dashboard/core/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/network/dio_client.dart';

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
  // ✅ لتتبع حالة الصوت بعد التهيئة
  bool _audioReady = false;
  // ✅ إصلاح: لإظهار مؤشر تحميل أثناء تنزيل الملف الصوتي عند أول ضغط
  // على زر التشغيل (كان المستخدم يضغط ولا يحدث شيء ظاهر لعدة ثوانٍ).
  bool _isAudioLoading = false;
  // ✅ إصلاح: لعدم استدعاء seek() في كل تحريك بسيط أثناء سحب سلايدر
  // الصوت (كان يستدعي seek على كل onChanged، مما يسبب أداءً ضعيفاً
  // وتقطيعاً أثناء السحب). القيمة الفعلية لا تُطبّق إلا عند الإفلات.
  double? _audioDragSeconds;
  // ✅ إصلاح جوهري: هذه هي الهيدرز الحقيقية المستخدَمة لكل الوسائط
  // (فيديو + صورة مصغّرة + تحميل الصوت). تُبنى من AuthService.getToken()
  // مباشرة — أي نفس المصدر الذي يقرأ منه DioClient.onRequest التوكن —
  // بدل قراءتها (خطأً) من DioClient.instance.options.headers التي لا
  // تحتوي على Authorization أبداً لأنه يُضاف ديناميكياً عبر Interceptor.
  Map<String, String> _mediaHeaders = const {};

  @override
  void initState() {
    super.initState();
    _loadMediaHeadersThenInitVideo();
  }

  Future<void> _loadMediaHeadersThenInitVideo() async {
    _mediaHeaders = await _authHeaders();
    if (!mounted) return;
    // نعيد البناء الآن حتى تحصل الصورة المصغّرة (CachedNetworkImage)
    // على الهيدرز الصحيحة أيضاً، ثم نهيّئ الفيديو.
    setState(() {});
    await _initVideo();
  }

  // ✅ إصلاح: إن أُعيد استخدام نفس الصفحة (نفس الـ State) لمنشور آخر
  // (مثلاً عبر PageView أو Navigator.pushReplacement مع نفس الـ key)،
  // كان الفيديو/الصوت القديم يبقى معروضاً لأن initState لا يُستدعى مجدداً.
  @override
  void didUpdateWidget(covariant PostDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _videoController?.removeListener(_videoListener);
      _videoController?.dispose();
      _videoController = null;
      _videoReady = false;
      _videoError = null;
      _isVideoPlaying = false;
      _videoPosition = Duration.zero;
      _videoDuration = Duration.zero;

      _audioPlayer?.dispose();
      _audioPlayer = null;
      _audioReady = false;
      _isAudioPlaying = false;
      _currentAudioUrl = null;
      _audioPosition = Duration.zero;
      _audioDuration = Duration.zero;

      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    // ✅ إصلاح: استخدام _getVideoUrl() بدلاً من videoUrl مباشرة
    final videoUrl = _getVideoUrl();
    if (videoUrl == null || videoUrl.isEmpty) return;

    try {
      debugPrint('🎬 VIDEO URL = $videoUrl');

      // ✅ إصلاح جوهري: video_player لا يستخدم Dio ولا يرسل تلقائياً
      // رأس Authorization المطلوب للوصول لملفات الوسائط المحمية.
      // نستخدم _mediaHeaders المحمّلة مسبقاً من AuthService.getToken()
      // مباشرة (نفس مصدر التوكن الذي يقرأه DioClient.onRequest).
      final headers =
          _mediaHeaders.isNotEmpty ? _mediaHeaders : await _authHeaders();

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: headers,
      );
      await controller.initialize();

      controller.addListener(_videoListener);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _videoController = controller;
        _videoReady = true;
        _videoDuration = controller.value.duration;
        _videoError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _videoError = 'فشل تحميل الفيديو: ${e.toString()}');
      }
    }
  }

  /// يبني رؤوس المصادقة (Authorization) لملفات الوسائط المحمية،
  /// بجلب التوكن مباشرة من AuthService — وهو نفس المصدر الذي يقرأه
  /// DioClient داخل onRequest Interceptor. (سابقاً كانت هذه الدالة
  /// تقرأ من DioClient.instance.options.headers، وهي لا تحتوي أبداً
  /// على Authorization لأنه يُضاف ديناميكياً في كل طلب من داخل
  /// الـ Interceptor وليس ضمن BaseOptions الثابتة).
  Future<Map<String, String>> _authHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      debugPrint('⚠️ [media auth] لا يوجد توكن من AuthService.getToken()!');
    }
    return headers;
  }

  void _videoListener() {
    final controller = _videoController;
    if (!mounted || controller == null) return;

    if (!_isSeeking) {
      setState(() {
        _isVideoPlaying = controller.value.isPlaying;
        _videoPosition = controller.value.position;
        _videoDuration = controller.value.duration;
      });
    }
  }

  Future<void> _initAudio(String url) async {
    if (_audioPlayer != null && _currentAudioUrl == url) return;

    _currentAudioUrl = url;
    await _audioPlayer?.dispose();
    _audioPlayer = AudioPlayer();
    _audioReady = false;

    try {
      // ✅ إصلاح جوهري: نفس مشكلة الفيديو — just_audio.setUrl() لا يرسل
      // رأس Authorization بشكل موثوق لملف محمي. نحمّل الملف محلياً أولاً
      // عبر Dio (الذي يرفق رأس المصادقة تلقائياً لكل طلباته)، ثم نشغّله
      // من القرص — تمامًا كما يفعل تطبيق المستخدم الذي يعمل بنجاح.
      final localPath = await _downloadAudioWithAuth(url);
      if (!mounted) return;

      await _audioPlayer!.setFilePath(localPath);

      // ✅ إصلاح: الاستماع لـ durationStream بدلاً من قراءة duration مرة واحدة
      _audioPlayer!.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _audioDuration = duration);
        }
      });

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

      if (mounted) {
        setState(() {
          _audioReady = true;
          _audioDuration = _audioPlayer!.duration ?? Duration.zero;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل الملف الصوتي')),
        );
      }
    }
  }

  /// يحمّل الملف الصوتي محلياً باستخدام Dio (يرفق رأس Authorization
  /// تلقائياً)، مع تخزينه مؤقتاً حتى لا يُعاد تحميله في كل مرة.
  Future<String> _downloadAudioWithAuth(String url) async {
    final dir = await getTemporaryDirectory();
    // ✅ إصلاح: سابقاً كان الكاش يعتمد على hash للرابط الكامل بما فيه
    // expires وsignature، وهذان يتغيّران في كل مرة يُعاد فيها توليد
    // الرابط الموقّع من الباك اند (حتى لو كان نفس الملف تماماً)، فكان
    // الكاش لا يُستخدم فعلياً أبداً ويتراكم ملف جديد على القرص في كل
    // مرة. الآن نعتمد فقط على مسار الرابط (بدون query) كمفتاح ثابت.
    final stablePath = Uri.tryParse(url)?.path ?? url;
    final cacheFile =
        File('${dir.path}/admin_post_audio_${stablePath.hashCode.abs()}.mp3');

    if (await cacheFile.exists()) {
      final size = await cacheFile.length();
      // ✅ إصلاح: كان أي ملف كاش موجود يُستخدم مباشرة بلا تحقق — حتى
      // لو كان في الأصل رسالة خطأ JSON (مثل UNAUTHENTICATED) محفوظة
      // خطأً كملف .mp3 (انظر الشرح أدناه). رسائل الخطأ عادة أقل من
      // 2KB بينما أي ملف صوتي حقيقي أكبر من ذلك بكثير.
      if (size > 2048) {
        debugPrint('📦 Using cached audio: ${cacheFile.path}');
        return cacheFile.path;
      }
      debugPrint('🗑️ حذف كاش صوتي فاسد/مشبوه (حجمه $size بايت فقط)');
      await cacheFile.delete();
    }

    debugPrint('⬇️ Downloading audio with auth headers: $url');
    final response = await DioClient.instance.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    // ✅ إصلاح جوهري: DioClient مضبوط بـ validateStatus للسماح بأي
    // status أقل من 500، لذا لا يرمي Dio استثناءً عند 401/403/404.
    // بدون هذا التحقق، كانت بايتات رسالة خطأ JSON (UNAUTHENTICATED)
    // تُكتب مباشرة كملف .mp3 على القرص فيفشل ExoPlayer عند تشغيله
    // بخطأ "None of the available extractors could read the stream" —
    // بالضبط ما شاهدناه في اللوق.
    if (response.statusCode != 200) {
      throw Exception(
        'فشل تحميل الملف الصوتي (HTTP ${response.statusCode}): '
        '${response.data}',
      );
    }

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('استجابة فارغة أثناء تحميل الملف الصوتي');
    }

    await cacheFile.writeAsBytes(bytes);
    debugPrint('✅ Audio saved: ${cacheFile.path} (${bytes.length} bytes)');
    return cacheFile.path;
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // ✅ إصلاح: دالة موحدة لجلب URL الفيديو من videoUrl أو media
  String? _getVideoUrl() {
    if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      return ApiConstants.mediaUrl(widget.post.videoUrl!);
    }
    try {
      final videoMedia = widget.post.media.firstWhere((m) => m.isVideo);
      return ApiConstants.mediaUrl(videoMedia.filePath);
    } catch (e) {
      return null;
    }
  }

  String? _getAudioUrl() {
    if (widget.post.audioUrl != null && widget.post.audioUrl!.isNotEmpty) {
      return ApiConstants.mediaUrl(widget.post.audioUrl!);
    }
    try {
      final audioMedia = widget.post.media.firstWhere((m) => m.isAudio);
      return ApiConstants.mediaUrl(audioMedia.filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // ✅ إصلاح: استخدام _getVideoUrl() للتحقق من وجود فيديو
    final hasVideo = _getVideoUrl() != null;
    final audioUrl = _getAudioUrl();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildPremiumAppBar(isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.0 : 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildTitle(isDark, isTablet),
                    const SizedBox(height: 16),
                    _buildAuthorAndDate(isDark),
                    const SizedBox(height: 24),
                    _buildContent(isDark),
                    const SizedBox(height: 24),
                    // ✅ إصلاح: استخدام hasVideo المبني على _getVideoUrl()
                    if (hasVideo) ...[
                      _buildVideoSection(isDark),
                      const SizedBox(height: 24),
                    ],
                    if (audioUrl != null) ...[
                      _buildAudioSection(isDark, audioUrl),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Premium App Bar ====================
  SliverAppBar _buildPremiumAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 340,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? Colors.black : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.post.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.post.hasThumbnail)
              CachedNetworkImage(
                imageUrl: ApiConstants.mediaUrl(widget.post.thumbnail!),
                // ✅ إصلاح: كانت الصورة المصغّرة تُطلب بدون أي Header
                // للمصادقة إطلاقاً، فتفشل بنفس خطأ UNAUTHENTICATED الذي
                // كان يظهر مع الفيديو.
                httpHeaders: _mediaHeaders,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 300),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    isDark ? Colors.black : Colors.white,
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Title ====================
  Widget _buildTitle(bool isDark, bool isTablet) {
    return Text(
      widget.post.title,
      style: TextStyle(
        fontSize: isTablet ? 32 : 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  // ==================== Author & Date ====================
  Widget _buildAuthorAndDate(bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          child: Text(
            widget.post.author?.name ?? 'ادمن',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.author?.name ?? 'ادمن',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                widget.post.displayDate,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_statusIcon(), size: 14, color: _statusColor()),
              const SizedBox(width: 4),
              Text(
                widget.post.status.arabicName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _statusColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== Content ====================
  Widget _buildContent(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Text(
        widget.post.content,
        style: TextStyle(
          fontSize: 16.4,
          height: 1.85,
          color: isDark ? Colors.white70 : Colors.grey.shade800,
        ),
      ),
    );
  }

  // ==================== Video Section ====================
  Widget _buildVideoSection(bool isDark) {
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
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildVideoCard(isDark),
      ],
    );
  }

  Widget _buildVideoCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.10),
          ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  // ✅ إصلاح: GestureDetector يغطي كامل الفيديو للتشغيل/الإيقاف
                  GestureDetector(
                    onTap: _toggleVideo,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        AnimatedOpacity(
                          opacity: _isVideoPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isVideoPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            // ✅ إصلاح: بدون هذا، كان _videoListener يستمر
                            // بتحديث _videoPosition من التشغيل الفعلي أثناء
                            // سحب المستخدم للسلايدر (لأن _isSeeking لم يكن
                            // يُضبط إلا عند onChangeEnd فقط)، فيسبب "قفز"
                            // مزعج في السلايدر أثناء السحب.
                            onChangeStart: (value) {
                              _isSeeking = true;
                            },
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
                            Text(
                              _formatDuration(_videoPosition),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(_videoDuration),
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

  // ==================== Audio Section ====================
  // ✅ إصلاح: استقبال audioUrl مباشرة بدلاً من استدعاء _getAudioUrl() مجدداً
  Widget _buildAudioSection(bool isDark, String audioUrl) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.audiotrack_rounded,
                  color: Colors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملف صوتي',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _getFileNameFromUrl(audioUrl),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ),
                    if (_audioDuration.inSeconds > 0)
                      Text(
                        _formatDuration(_audioDuration),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _isAudioLoading ? null : () => _toggleAudio(audioUrl),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.teal.shade400, Colors.teal.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isAudioLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Icon(
                          _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
          // ✅ إصلاح: إظهار الـ Slider بمجرد تهيئة الصوت وليس فقط أثناء التشغيل
          if (_audioReady) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDuration(_audioPosition),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
                Expanded(
                  child: Slider(
                    // ✅ إصلاح: أثناء السحب نعرض القيمة المحلية
                    // (_audioDragSeconds) بدلاً من الموضع الفعلي، لتفادي
                    // "تقطيع" الحركة الناتج عن استدعاء seek() في كل
                    // إطار من السحب.
                    value: _audioDragSeconds ??
                        (_audioDuration.inSeconds == 0
                            ? 0
                            : _audioPosition.inSeconds
                                .clamp(0, _audioDuration.inSeconds)
                                .toDouble()),
                    max: _audioDuration.inSeconds > 0
                        ? _audioDuration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      setState(() => _audioDragSeconds = value);
                    },
                    onChangeEnd: (value) {
                      _audioPlayer?.seek(Duration(seconds: value.toInt()));
                      setState(() => _audioDragSeconds = null);
                    },
                    activeColor: Colors.teal,
                    inactiveColor: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                  ),
                ),
                Text(
                  _formatDuration(_audioDuration),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== Helpers ====================
  void _toggleVideo() {
    if (_videoController == null) return;
    if (_isVideoPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _toggleAudio(String url) async {
    // إذا كان الصوت جاهزاً مسبقاً لنفس الرابط، لا حاجة لإظهار التحميل
    final needsInit = _audioPlayer == null || _currentAudioUrl != url;
    if (needsInit && mounted) {
      setState(() => _isAudioLoading = true);
    }

    await _initAudio(url);

    if (mounted) {
      setState(() => _isAudioLoading = false);
    }
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
    // ✅ إصلاح: كان يستخدم url.split('/').last مباشرة، وبما أن روابط
    // signed-media تحتوي على query params (?expires=...&signature=...)
    // كان الاسم الظاهر للمستخدم يتضمن كل هذا النص العشوائي بدلاً من
    // اسم/معرّف الملف فقط. نستخدم Uri.path لتجاهل الـ query تماماً.
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : url;
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
