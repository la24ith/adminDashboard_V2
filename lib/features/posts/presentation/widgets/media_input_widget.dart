import 'package:flutter/material.dart';

enum MediaInputType { upload, url }

class MediaInputWidget extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? initialUrl;
  final Function(String?) onChanged;
  final bool isImage;

  const MediaInputWidget({
    super.key,
    required this.title,
    required this.icon,
    this.initialUrl,
    required this.onChanged,
    this.isImage = true,
  });

  @override
  State<MediaInputWidget> createState() => _MediaInputWidgetState();
}

class _MediaInputWidgetState extends State<MediaInputWidget> {
  MediaInputType _inputType = MediaInputType.url;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildToggleButton('رابط', MediaInputType.url),
              const SizedBox(width: 4),
              _buildToggleButton('رفع ملف', MediaInputType.upload),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Content
        if (_inputType == MediaInputType.url)
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'أدخل رابط ال${widget.title}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: widget.onChanged,
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade50,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 32, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط لاختيار ${widget.title}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

        // Preview
        if (_urlController.text.isNotEmpty && widget.isImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _urlController.text,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  width: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToggleButton(String label, MediaInputType type) {
    final isSelected = _inputType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _inputType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
