import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NotificationFormPage extends StatefulWidget {
  final Map<String, dynamic>? notification;
  final Function(Map<String, dynamic>) onSave;

  const NotificationFormPage({
    super.key,
    this.notification,
    required this.onSave,
  });

  @override
  State<NotificationFormPage> createState() => _NotificationFormPageState();
}

class _NotificationFormPageState extends State<NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late DateTime _sendDate;
  late int _validityDays;
  late List<String> _targetTypes;
  late String _type;
  late String _targetType;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isScheduled = true;

  final List<String> _typeOptions = ['info', 'warning', 'success', 'error', 'reminder'];
  final List<String> _targetTypeOptions = ['all', 'specific', 'role_based'];
  final List<String> _targetAudienceOptions = ['الجميع', 'مرضى السكري', 'الأشبال', 'نشطين', 'غير نشطين'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.notification?['title'] ?? '');
    _messageController = TextEditingController(text: widget.notification?['message'] ?? '');

    final isAlreadySent = widget.notification?['sent_at'] != null ||
        (widget.notification?['send_at'] != null &&
            DateTime.parse(widget.notification!['send_at']).isBefore(DateTime.now()));

    if (widget.notification?['send_at'] != null && !isAlreadySent) {
      _sendDate = DateTime.parse(widget.notification!['send_at']);
      _isScheduled = true;
    } else {
      _sendDate = DateTime.now().add(const Duration(hours: 1));
      _isScheduled = true;
    }

    _validityDays = widget.notification?['validity_days'] ?? 7;
    _targetTypes = widget.notification?['target_filters'] != null
        ? List<String>.from(widget.notification!['target_filters'])
        : ['الجميع'];
    _type = widget.notification?['type'] ?? 'info';
    _targetType = widget.notification?['target_type'] ?? 'all';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'info': return 'معلومات';
      case 'warning': return 'تحذير';
      case 'success': return 'نجاح';
      case 'error': return 'خطأ';
      case 'reminder': return 'تذكير';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.notification?['sent_at'] != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.notification == null ? 'إضافة إشعار جديد' : 'تعديل الإشعار',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error))),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ],
                  ),
                ),

              if (isReadOnly)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(child: Text('هذا الإشعار تم إرساله بالفعل، لا يمكن تعديله')),
                    ],
                  ),
                ),

              TextFormField(
                controller: _titleController,
                readOnly: isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'العنوان مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _messageController,
                readOnly: isReadOnly,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'نص الإشعار',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'نص الإشعار مطلوب' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع الإشعار',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _typeOptions.map((type) => DropdownMenuItem(value: type, child: Text(_getTypeLabel(type)))).toList(),
                onChanged: (value) => setState(() => _type = value!),
                validator: (v) => v == null ? 'نوع الإشعار مطلوب' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _targetType,
                decoration: const InputDecoration(
                  labelText: 'نوع الاستهداف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'specific', child: Text('محدد')),
                  DropdownMenuItem(value: 'role_based', child: Text('حسب الدور')),
                ],
                onChanged: (value) => setState(() => _targetType = value!),
                validator: (v) => v == null ? 'نوع الاستهداف مطلوب' : null,
              ),
              const SizedBox(height: 16),

              if (!isReadOnly)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('إرسال فوري'),
                              value: false,
                              groupValue: _isScheduled,
                              onChanged: (value) {
                                setState(() {
                                  _isScheduled = false;
                                  _sendDate = DateTime.now();
                                });
                              },
                              activeColor: AppColors.accent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('جدولة لاحقاً'),
                              value: true,
                              groupValue: _isScheduled,
                              onChanged: (value) {
                                setState(() {
                                  _isScheduled = true;
                                  _sendDate = DateTime.now().add(const Duration(hours: 1));
                                });
                              },
                              activeColor: AppColors.accent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      if (_isScheduled)
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('تاريخ ووقت الإرسال'),
                          subtitle: Text(
                            '${_sendDate.day}/${_sendDate.month}/${_sendDate.year} ${_sendDate.hour}:${_sendDate.minute.toString().padLeft(2, '0')}',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _sendDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_sendDate),
                              );
                              if (time != null) {
                                setState(() {
                                  _sendDate = DateTime(
                                    date.year, date.month, date.day,
                                    time.hour, time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      if (_isScheduled)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '📌 سيتم إرسال الإشعار تلقائياً في التاريخ المحدد',
                            style: TextStyle(fontSize: 12, color: AppColors.info),
                          ),
                        ),
                      if (!_isScheduled)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '⚡ سيتم إرسال الإشعار فوراً بعد الحفظ',
                            style: TextStyle(fontSize: 12, color: AppColors.success),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _validityDays,
            
                decoration: const InputDecoration(
                  labelText: 'مدة الصلاحية (بالأيام)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('يوم واحد')),
                  DropdownMenuItem(value: 3, child: Text('3 أيام')),
                  DropdownMenuItem(value: 7, child: Text('أسبوع')),
                  DropdownMenuItem(value: 14, child: Text('أسبوعين')),
                  DropdownMenuItem(value: 30, child: Text('شهر')),
                ],
                onChanged: (value) => setState(() => _validityDays = value!),
              ),
              const SizedBox(height: 16),

              if (_targetType == 'specific' && !isReadOnly)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الفئة المستهدفة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _targetAudienceOptions.map((target) {
                        final isSelected = _targetTypes.contains(target);
                        return FilterChip(
                          label: Text(target),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (target == 'الجميع') {
                                  _targetTypes = ['الجميع'];
                                } else {
                                  _targetTypes.remove('الجميع');
                                  _targetTypes.add(target);
                                }
                              } else {
                                _targetTypes.remove(target);
                                if (_targetTypes.isEmpty) _targetTypes = ['الجميع'];
                              }
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.accent.withOpacity(0.1),
                          checkmarkColor: AppColors.accent,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isSaving || isReadOnly) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.accent,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('حفظ'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> notificationData = {
      'title': _titleController.text,
      'message': _messageController.text,
      'type': _type,
      'target_type': _targetType,
      'validity_days': _validityDays,
    };

    if (_isScheduled) {
      if (_sendDate.isAfter(DateTime.now())) {
        notificationData['send_at'] = _sendDate.toIso8601String();
      } else {
        notificationData['send_at'] = DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        setState(() => _sendDate = DateTime.now().add(const Duration(hours: 1)));
      }
    }

    if (_targetType == 'specific') {
      notificationData['target_filters'] = _targetTypes;
    }

    try {
      await widget.onSave(notificationData);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
        _isLoading = false;
        _isSaving = false;
      });
    }
  }
}