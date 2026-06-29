enum NotificationStatus { scheduled, sent, expired }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String targetType;
  final DateTime? sendAt;
  final DateTime? sentAt;
  final DateTime? expiresAt;
  final int validityDays;
  final List<String> targetFilters;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetType,
    this.sendAt,
    this.sentAt,
    this.expiresAt,
    this.validityDays = 7,
    this.targetFilters = const [],
    this.createdAt,
  });

  // ✅ دالة حساب الحالة المركزية — المصدر الوحيد للحقيقة
  // الترتيب الصحيح: expired أولاً ← sent ← scheduled ← افتراضي
  NotificationStatus get status {
    final now = DateTime.now();

    // منتهي: مضى وقت انتهاء الصلاحية
    if (expiresAt != null && expiresAt!.isBefore(now)) {
      return NotificationStatus.expired;
    }

    // مرسل: يوجد sent_at أو مضى send_at
    if (sentAt != null) return NotificationStatus.sent;
    if (sendAt != null && sendAt!.isBefore(now)) return NotificationStatus.sent;

    // مجدول: send_at في المستقبل
    if (sendAt != null && sendAt!.isAfter(now)) {
      return NotificationStatus.scheduled;
    }

    return NotificationStatus.sent;
  }

  // ✅ نفس المنطق لكن يُعيد String — للتوافق مع الفلتر
  String get statusKey {
    switch (status) {
      case NotificationStatus.scheduled:
        return 'scheduled';
      case NotificationStatus.sent:
        return 'sent';
      case NotificationStatus.expired:
        return 'expired';
    }
  }

  String get remainingTime {
    final now = DateTime.now();
    switch (status) {
      case NotificationStatus.scheduled:
        final diff = sendAt!.difference(now);
        if (diff.inDays > 0) return 'يتبقى ${diff.inDays} يوم';
        if (diff.inHours > 0) return 'يتبقى ${diff.inHours} ساعة';
        return 'يتبقى ${diff.inMinutes} دقيقة';
      case NotificationStatus.sent:
        if (expiresAt != null && expiresAt!.isAfter(now)) {
          final diff = expiresAt!.difference(now);
          if (diff.inDays > 0) return 'تنتهي بعد ${diff.inDays} يوم';
          if (diff.inHours > 0) return 'تنتهي بعد ${diff.inHours} ساعة';
          return 'تنتهي قريباً';
        }
        return '';
      case NotificationStatus.expired:
        return 'منتهية';
    }
  }

  String get formattedSendAt {
    if (sendAt == null) return '—';
    return '${sendAt!.day}/${sendAt!.month}/${sendAt!.year} '
        '${sendAt!.hour}:${sendAt!.minute.toString().padLeft(2, '0')}';
  }

  String get validityDaysText {
    if (validityDays >= 30) return '${validityDays ~/ 30} شهر';
    if (validityDays >= 7) return '${validityDays ~/ 7} أسبوع';
    return '$validityDays يوم';
  }

  // ✅ factory من Map — نقطة تحويل واحدة في كل التطبيق
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
      targetType: json['target_type'] as String? ?? 'all',
      sendAt: json['send_at'] != null
          ? DateTime.tryParse(json['send_at'] as String)
          : null,
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      validityDays: json['validity_days'] as int? ?? 7,
      targetFilters: json['target_filters'] != null
          ? List<String>.from(json['target_filters'] as List)
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'target_type': targetType,
      if (sendAt != null) 'send_at': sendAt!.toIso8601String(),
      if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      'validity_days': validityDays,
      if (targetFilters.isNotEmpty) 'target_filters': targetFilters,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? targetType,
    DateTime? sendAt,
    DateTime? sentAt,
    DateTime? expiresAt,
    int? validityDays,
    List<String>? targetFilters,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      sendAt: sendAt ?? this.sendAt,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      validityDays: validityDays ?? this.validityDays,
      targetFilters: targetFilters ?? this.targetFilters,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
