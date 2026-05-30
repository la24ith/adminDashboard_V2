import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';

class AdFormPage extends StatefulWidget {
  final Map<String, dynamic>? ad;
  final Function(Map<String, dynamic>) onSave;

  const AdFormPage({super.key, this.ad, required this.onSave});

  @override
  State<AdFormPage> createState() => _AdFormPageState();
}

class _AdFormPageState extends State<AdFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageUrlController;
  late TextEditingController _linkUrlController;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isActive;
  bool _hasImage = true;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Image upload variables
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _imageUploadError;

  String _type = 'banner';
  String _linkType = 'external';
  List<String> _targetAudience = ['general'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ad?['title'] ?? '');
    _contentController =
        TextEditingController(text: widget.ad?['content'] ?? '');
    _imageUrlController =
        TextEditingController(text: widget.ad?['image_url'] ?? '');
    _linkUrlController =
        TextEditingController(text: widget.ad?['link_url'] ?? '');
    _startDate = widget.ad?['start_date'] != null
        ? DateTime.parse(widget.ad!['start_date'])
        : DateTime.now();
    _endDate = widget.ad?['end_date'] != null
        ? DateTime.parse(widget.ad!['end_date'])
        : DateTime.now().add(const Duration(days: 30));
    _isActive = widget.ad?['is_active'] ?? true;
    _hasImage = widget.ad?['image_url'] != null &&
        widget.ad!['image_url'].toString().isNotEmpty;
    _type = widget.ad?['type'] ?? 'banner';
    _linkType = widget.ad?['link_type'] ?? 'external';
    _targetAudience = widget.ad?['target_audience'] != null
        ? List<String>.from(widget.ad!['target_audience'])
        : ['general'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageUploadError = null;
      });
      await _simulateImageUpload();
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageUploadError = null;
      });
      await _simulateImageUpload();
    }
  }

  Future<void> _simulateImageUpload() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
      _imageUploadError = null;
    });

    try {
      // هنا يمكنك استبدال هذا برفع الصورة الفعلي إلى الخادم
      // مؤقتاً نستخدم رابط تجريبي
      await Future.delayed(const Duration(seconds: 1));

      // استخدام رابط تجريبي - استبدل هذا برفع الصورة الفعلي
      final tempUrl =
          'https://picsum.photos/id/${_selectedImage!.hashCode.abs() % 100}/400/300';

      setState(() {
        _imageUrlController.text = tempUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _imageUploadError = 'فشل رفع الصورة: ${e.toString()}';
        _isUploadingImage = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _imageUrlController.clear();
      _imageUploadError = null;
      _hasImage = false;
    });
  }

  void _toggleTargetAudience(String value) {
    setState(() {
      if (_targetAudience.contains(value)) {
        _targetAudience.remove(value);
      } else {
        _targetAudience.add(value);
      }
      if (_targetAudience.isEmpty) {
        _targetAudience.add('general');
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_hasImage &&
        _imageUrlController.text.isEmpty &&
        _selectedImage == null) {
      setState(() {
        _errorMessage = 'الرجاء إضافة صورة للإعلان';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _isLoading = true;
      _errorMessage = null;
    });

    final adData = {
      'title': _titleController.text,
      'content': _contentController.text,
      'type': _type,
      'link_type': _linkType,
      'position': 'top',
      'start_date': _startDate.toIso8601String().split('T')[0],
      'end_date': _endDate.toIso8601String().split('T')[0],
      'is_active': _isActive,
      'target_audience': _targetAudience,
      if (_linkUrlController.text.isNotEmpty)
        'link_url': _linkUrlController.text,
      if (_hasImage && _imageUrlController.text.isNotEmpty)
        'image_url': _imageUrlController.text,
    };

    print('📤 Sending ad data: $adData');

    try {
      await widget.onSave(adData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
        _isLoading = false;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.ad == null ? 'إضافة إعلان جديد' : 'تعديل الإعلان'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإعلان *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'محتوى الإعلان',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // Ad Type
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع الإعلان',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'banner', child: Text('بانر')),
                  DropdownMenuItem(value: 'popup', child: Text('منبثق')),
                  DropdownMenuItem(value: 'inline', child: Text('مدمج')),
                  DropdownMenuItem(value: 'video', child: Text('فيديو')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 16),

              // Link Type
              DropdownButtonFormField<String>(
                value: _linkType,
                decoration: const InputDecoration(
                  labelText: 'نوع الرابط',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'external', child: Text('رابط خارجي')),
                  DropdownMenuItem(value: 'internal', child: Text('داخلي')),
                  DropdownMenuItem(value: 'none', child: Text('بدون رابط')),
                ],
                onChanged: (value) => setState(() => _linkType = value!),
              ),
              const SizedBox(height: 16),

              // Link URL
              if (_linkType != 'none')
                TextFormField(
                  controller: _linkUrlController,
                  decoration: const InputDecoration(
                    labelText: 'رابط الإعلان',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.open_in_new),
                    hintText: 'https://example.com',
                  ),
                ),
              const SizedBox(height: 16),

              // Target Audience
              const Text(
                'الجمهور المستهدف',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTargetChip('general', 'عام'),
                  _buildTargetChip('diabetes', 'مرضى السكري'),
                  _buildTargetChip('cubs', 'الأشبال'),
                ],
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('تاريخ البداية'),
                subtitle: Text(
                    '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),

              // End Date
              ListTile(
                leading: const Icon(Icons.event_busy),
                title: const Text('تاريخ النهاية'),
                subtitle: Text(
                    '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
              ),

              // Active Switch
              SwitchListTile(
                title: const Text('تفعيل الإعلان'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                activeColor: AppColors.accent,
              ),

              const SizedBox(height: 16),

              // Image Section
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('إضافة صورة'),
                      value: _hasImage,
                      onChanged: (value) {
                        setState(() {
                          _hasImage = value;
                          if (!value) _clearImage();
                        });
                      },
                    ),
                    if (_hasImage) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Preview
                            if (_imageUrlController.text.isNotEmpty ||
                                _selectedImage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              _imageUrlController.text,
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                height: 150,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                    child: Icon(
                                                        Icons.broken_image,
                                                        size: 40)),
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: _clearImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Image URL Field
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'رابط الصورة',
                                prefixIcon: Icon(Icons.link),
                                border: OutlineInputBorder(),
                                hintText: 'https://example.com/image.jpg',
                              ),
                              validator: (v) => _hasImage &&
                                      (v == null || v.isEmpty) &&
                                      _selectedImage == null
                                  ? 'رابط الصورة مطلوب'
                                  : null,
                            ),

                            const SizedBox(height: 12),

                            // Upload Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _pickImageFromGallery,
                                    icon: const Icon(Icons.photo_library,
                                        size: 18),
                                    label: const Text('اختر من المعرض'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _pickImageFromCamera,
                                    icon:
                                        const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('التقاط صورة'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_isUploadingImage) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                              const SizedBox(height: 8),
                              const Text(
                                'جاري رفع الصورة...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],

                            if (_imageUploadError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _imageUploadError!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isUploadingImage) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'حفظ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetChip(String value, String label) {
    final isSelected = _targetAudience.contains(value);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleTargetAudience(value),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent.withOpacity(0.1),
      checkmarkColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accent : AppColors.textSecondary,
      ),
    );
  }
}
