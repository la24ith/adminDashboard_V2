// lib/new_app/feature/post_details/presentation/widgets/drive_preview_widget.dart
//
// ✅ معاينة ملفات غوغل درايف (فيديو أو ملفات عامة) داخل التطبيق عبر
// WebView، برابط /preview الرسمي من غوغل (الوحيد الموثوق للستريمنغ
// المباشر؛ روابط uc?export=download مخصصة للتحميل وليست للعرض).
//
// ✅ إصلاح جوهري: onWebResourceError يُستدعى عند فشل تحميل أي مورد
// داخل الصفحة (سكريبت، iframe فرعي، صورة، تتبّع...) وليس فقط عند فشل
// الصفحة الرئيسية. وصفحة /preview بتاعة غوغل تحمّل داخلها عدة iframes
// فرعية (مثل auth_warmup)، وأي واحد منها يفشل (حتى لو الفيديو نفسه
// اشتغل أو على وشك الاشتغال) كان يخلي الكود يعتبر "كله فشل" ويعرض
// رسالة خطأ خاطئة. الحل: نتجاهل أي خطأ لا يخص الإطار الرئيسي
// (error.isForMainFrame == false) ونعتمد فقط على أخطاء الإطار الرئيسي
// كمؤشر فعلي للفشل.
//
// أضف الحزمة عبر: flutter pub add webview_flutter url_launcher

import 'package:admin_dashboard/core/utils/media_source_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleDrivePreview extends StatefulWidget {
  final String driveUrl;
  final double? height;
  final BorderRadius? borderRadius;

  const GoogleDrivePreview({
    super.key,
    required this.driveUrl,
    this.height,
    this.borderRadius,
  });

  @override
  State<GoogleDrivePreview> createState() => _GoogleDrivePreviewState();
}

class _GoogleDrivePreviewState extends State<GoogleDrivePreview> {
  WebViewController? _webController;
  bool _isLoading = true;
  bool _hasError = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant GoogleDrivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ إصلاح: لو أُعيد استخدام نفس الودجت (نفس الـ State) لملف درايف
    // آخر، نعيد التحميل بدل ما يبقى المحتوى القديم ظاهراً.
    if (oldWidget.driveUrl != widget.driveUrl) {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
      _setup();
    }
  }

  void _setup() {
    final fileId = MediaSourceHelper.extractDriveFileId(widget.driveUrl);

    if (fileId == null) {
      setState(() => _hasError = true);
      return;
    }

    final previewUrl = 'https://drive.google.com/file/d/$fileId/preview';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          // ✅ الإصلاح الأساسي: تجاهل أي خطأ لا يخص الإطار الرئيسي.
          // صفحة /preview تحمّل داخلها iframes فرعية (auth_warmup وغيرها)
          // قد تفشل بشكل طبيعي وغير مؤثر على تشغيل الفيديو نفسه — لا
          // نعتبر ذلك فشلاً إلا إذا كان الإطار الرئيسي هو من فشل فعلاً.
          onWebResourceError: (error) {
            final isMainFrameFailure = error.isForMainFrame ?? true;
            if (!isMainFrameFailure) {
              debugPrint(
                '⚠️ [Drive] تجاهل خطأ مورد فرعي (غير مؤثر): '
                '${error.description}',
              );
              return;
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(previewUrl));

    if (mounted) setState(() {});
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
    });
    _setup();
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.driveUrl);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _hasError || _webController == null
            ? _buildErrorState()
            : Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // ✅ ظهور تدريجي أنيق للمشغّل بدل ظهوره فجأة بمجرد
                  // انتهاء التحميل — يعطي إحساساً أكثر احترافية.
                  AnimatedOpacity(
                    opacity: _isLoading ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    child: WebViewWidget(controller: _webController!),
                  ),
                  if (_isLoading) _buildLoadingState(),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.tealAccent.shade400,
                  value:
                      _progress > 0 && _progress < 100 ? _progress / 100 : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _progress > 0
                    ? 'جاري التحميل... $_progress%'
                    : 'جاري التحميل...',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'غوغل درايف',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Colors.white54, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذر عرض ملف غوغل درايف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'تأكد أن الملف مشارك بإعداد "أي شخص لديه الرابط"',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إعادة المحاولة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('فتح في درايف'),
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
          ],
        ),
      ),
    );
  }
}
