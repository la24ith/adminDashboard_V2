// lib/features/posts/presentation/widgets/external_video_player.dart
//
// ويدجت موحّدة لعرض الفيديوهات الخارجية (يوتيوب، غوغل درايف، فيسبوك،
// فيميو، وأي منصة أخرى) داخل التطبيق مباشرة قدر الإمكان:
//
// - يوتيوب: تشغيل حقيقي داخل التطبيق عبر youtube_player_flutter
//   (بدون WebView — أداء أفضل وتحكّم كامل بالتشغيل).
// - غوغل درايف: تضمين عبر WebView برابط المعاينة الرسمي من غوغل
//   (drive.google.com/file/d/{id}/preview) المخصّص أصلاً للعرض
//   المباشر داخل iframe/WebView.
// - فيسبوك / فيميو: محاولة تضمين عبر WebView (روابط التضمين
//   الرسمية)، مع ظهور تلقائي لزر "فتح خارجياً" عند فشل التحميل.
// - أي منصة أخرى غير معروفة: لا يوجد رابط تضمين موثوق بشكل عام،
//   فيُعرض زر واضح لفتح الرابط خارجياً مباشرة.
//
// في كل الحالات يوجد أيضاً زر صغير ثابت "فتح خارجياً" أعلى المشغّل،
// حتى يملك المستخدم دائماً مخرجاً بديلاً (فتح تطبيق يوتيوب/فيسبوك
// المثبت مثلاً قد يعطي تجربة أفضل من التضمين).
//
// ⚠️ يتطلّب هذا الويدجت الحزم التالية في pubspec.yaml:
//   youtube_player_flutter: ^10.0.1
//   webview_flutter: ^4.14.0
//   url_launcher: ^6.3.2
//
// ملاحظة مهمة: الإصدار 10.x من youtube_player_flutter هو إعادة كتابة
// كاملة مبنية فوق youtube_player_iframe (بدل flutter_inappwebview
// القديم). الـ API القديم (initialVideoId + flags على YoutubePlayer،
// showVideoProgressIndicator، progressIndicatorColor، convertUrlToId)
// غير موجود إطلاقاً في هذا الإصدار. الطريقة الصحيحة الآن:
//   YoutubePlayerController.fromVideoId(videoId: ..., autoPlay: ...,
//       params: YoutubePlayerParams(...))
// والتخلص من المتحكم يتم عبر controller.close() بدل dispose().
// استخراج معرّف الفيديو من الرابط يتم يدوياً عبر
// VideoProviderDetector.extractYoutubeId لأن الحزمة لم تعد تُصدّر
// دالة تحويل رابط إلى معرّف بشكل عام.

import 'package:admin_dashboard/features/posts/presentation/widgets/video_provider_detector.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExternalVideoPlayer extends StatefulWidget {
  /// الرابط الأصلي كما أرسله الخادم (external_url أو video_url).
  final String url;

  /// المزوّد كما حدّده الخادم إن وُجد ('youtube' | 'vimeo' | 'facebook'
  /// | 'google_drive' | null). عند null يتم اكتشافه من الرابط نفسه.
  final String? provider;

  final BorderRadius? borderRadius;

  /// يُستخدم فقط لتضمين WebView والحالات البديلة (يوتيوب يحسب
  /// ارتفاعه تلقائياً من نسبة العرض إلى الارتفاع 16:9).
  final double height;

  const ExternalVideoPlayer({
    super.key,
    required this.url,
    this.provider,
    this.borderRadius,
    this.height = 230,
  });

  @override
  State<ExternalVideoPlayer> createState() => _ExternalVideoPlayerState();
}

class _ExternalVideoPlayerState extends State<ExternalVideoPlayer> {
  late String _provider;
  YoutubePlayerController? _ytController;
  WebViewController? _webController;

  bool _webLoading = true;
  bool _webFailed = false;

  @override
  void initState() {
    super.initState();
    _provider =
        widget.provider ?? VideoProviderDetector.detect(widget.url) ?? 'other';
    _setup();
  }

  @override
  void didUpdateWidget(covariant ExternalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _ytController?.close();
      _ytController = null;
      _webController = null;
      _webLoading = true;
      _webFailed = false;
      _provider = widget.provider ??
          VideoProviderDetector.detect(widget.url) ??
          'other';
      _setup();
    }
  }

  void _setup() {
    switch (_provider) {
      case VideoProviderDetector.youtube:
        final id = VideoProviderDetector.extractYoutubeId(widget.url);
        if (id != null) {
          _ytController = YoutubePlayerController.fromVideoId(
            videoId: id,
            autoPlay: false,
            params: const YoutubePlayerParams(
              showFullscreenButton: true,
              showControls: true,
              mute: false,
            ),
          );
        }
        break;

      case VideoProviderDetector.googleDrive:
      case VideoProviderDetector.facebook:
      case VideoProviderDetector.vimeo:
        final embed =
            VideoProviderDetector.buildEmbedUrl(widget.url, _provider);
        if (embed != null) {
          _webController = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.black)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (_) {
                  if (mounted) setState(() => _webLoading = true);
                },
                onPageFinished: (_) {
                  if (mounted) setState(() => _webLoading = false);
                },
                onWebResourceError: (_) {
                  if (mounted) {
                    setState(() {
                      _webLoading = false;
                      _webFailed = true;
                    });
                  }
                },
              ),
            )
            ..loadRequest(Uri.parse(embed));
        }
        break;

      default:
        // منصة غير معروفة: لا يوجد رابط تضمين موثوق — يُعرض زر فتح خارجي فقط
        break;
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(24);

    Widget content;
    if (_provider == VideoProviderDetector.youtube && _ytController != null) {
      // ✅ الإصدار 10.x يعرض شريط تقدّم وأزرار تحكّم Material مدمجة
      // تلقائياً، لذا لا حاجة لأي معاملات إضافية هنا.
      content = YoutubePlayer(
        controller: _ytController!,
        aspectRatio: 16 / 9,
      );
    } else if (_webController != null) {
      content = SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _webController!),
            if (_webLoading)
              const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            if (_webFailed) _buildFailedOverlay(),
          ],
        ),
      );
    } else {
      content = _buildUnsupportedFallback();
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            content,
            Positioned(
              top: 10,
              left: 10,
              child: _buildOpenExternallyButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenExternallyButton() {
    return Material(
      color: Colors.black.withOpacity(0.55),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: _openExternally,
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'فتح خارجياً',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailedOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 32),
              const SizedBox(height: 10),
              Text(
                'تعذر تشغيل فيديو ${VideoProviderDetector.arabicLabel(_provider)} داخل التطبيق',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('فتح الفيديو خارجياً'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedFallback() {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.ondemand_video,
                  color: Colors.white.withOpacity(0.8), size: 34),
              const SizedBox(height: 10),
              const Text(
                'لا يمكن تشغيل هذا الرابط داخل التطبيق',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('فتح الفيديو خارجياً'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
