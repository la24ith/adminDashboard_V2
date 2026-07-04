// lib/new_app/feature/post_details/presentation/widgets/drive_preview_widget.dart
//
// ✅ معاينة ملفات غوغل درايف (فيديو أو ملفات عامة) داخل التطبيق عبر WebView
// نستخدم رابط /preview الرسمي من غوغل لأنه الوحيد الذي يدعم الستريمنغ
// بشكل موثوق (روابط uc?export=download مخصصة للتحميل وليست للعرض المباشر)
// أضف الحزمة عبر: flutter pub add webview_flutter

import 'package:admin_dashboard/core/utils/media_source_helper.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GoogleDrivePreview extends StatefulWidget {
  final String driveUrl;

  const GoogleDrivePreview({super.key, required this.driveUrl});

  @override
  State<GoogleDrivePreview> createState() => _GoogleDrivePreviewState();
}

class _GoogleDrivePreviewState extends State<GoogleDrivePreview> {
  WebViewController? _webController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    final fileId = MediaSourceHelper.extractDriveFileId(widget.driveUrl);

    if (fileId == null) {
      _hasError = true;
      return;
    }

    final previewUrl = 'https://drive.google.com/file/d/$fileId/preview';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _webController == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.white54, size: 40),
                SizedBox(height: 8),
                Text(
                  'تعذر عرض ملف غوغل درايف',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        WebViewWidget(controller: _webController!),
        if (_isLoading) const CircularProgressIndicator(color: Colors.teal),
      ],
    );
  }
}
