// lib/core/widgets/advanced_image_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/api_constants.dart';

class AdvancedImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final String? fallbackAsset;

  const AdvancedImageWidget({
    super.key,
    this.imageUrl,
    this.height = 160,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.fallbackAsset,
  });

  @override
  State<AdvancedImageWidget> createState() => _AdvancedImageWidgetState();
}

class _AdvancedImageWidgetState extends State<AdvancedImageWidget> {
  String? _currentUrl;
  int _retryCount = 0;
  List<String> _alternativeUrls = [];

  @override
  void initState() {
    super.initState();
    _prepareUrls();
  }

  void _prepareUrls() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return;

    _alternativeUrls = ApiConstants.getAlternativeUrls(widget.imageUrl!);
    _currentUrl = _alternativeUrls.first;
  }

  void _tryNextUrl() {
    if (_retryCount < _alternativeUrls.length - 1) {
      setState(() {
        _retryCount++;
        _currentUrl = _alternativeUrls[_retryCount];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: _currentUrl!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      placeholder: (context, url) => _buildLoading(),
      errorWidget: (context, url, error) {
        if (_retryCount < _alternativeUrls.length - 1) {
          _tryNextUrl();
          return _buildLoading();
        }
        return _buildError();
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: widget.height,
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              'فشل تحميل الصورة',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(Icons.image_not_supported,
            size: 40, color: Colors.grey.shade400),
      ),
    );
  }
}
