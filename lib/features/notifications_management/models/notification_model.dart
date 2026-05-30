enum NotificationStatus { scheduled, sent, expired }

class NotificationModel {
  final String id;
  final String text;
  final DateTime sendDate;
  final Duration expiryDuration;
  final NotificationStatus status;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.text,
    required this.sendDate,
    required this.expiryDuration,
    required this.status,
    this.createdAt,
  });

  DateTime get expiryDate => sendDate.add(expiryDuration);

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isScheduled => sendDate.isAfter(DateTime.now());

  String get remainingTime {
    if (isScheduled) {
      final diff = sendDate.difference(DateTime.now());
      if (diff.inDays > 0) return 'يتبقى ${diff.inDays} يوم';
      if (diff.inHours > 0) return 'يتبقى ${diff.inHours} ساعة';
      return 'يتبقى ${diff.inMinutes} دقيقة';
    } else if (status == NotificationStatus.sent && !isExpired) {
      final diff = expiryDate.difference(DateTime.now());
      if (diff.inDays > 0) return 'تنتهي بعد ${diff.inDays} يوم';
      if (diff.inHours > 0) return 'تنتهي بعد ${diff.inHours} ساعة';
      return 'تنتهي قريباً';
    } else if (isExpired || status == NotificationStatus.expired) {
      return 'منتهية';
    }
    return '';
  }

  String get formattedDate {
    return '${sendDate.day}/${sendDate.month}/${sendDate.year}';
  }

  String get formattedTime {
    return '${sendDate.hour}:${sendDate.minute.toString().padLeft(2, '0')}';
  }

  String get expiryDurationText {
    if (expiryDuration.inDays >= 30) {
      final months = expiryDuration.inDays ~/ 30;
      return '$months شهر';
    } else if (expiryDuration.inDays >= 7) {
      final weeks = expiryDuration.inDays ~/ 7;
      return '$weeks أسبوع';
    } else {
      return '${expiryDuration.inDays} يوم';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? text,
    DateTime? sendDate,
    Duration? expiryDuration,
    NotificationStatus? status,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sendDate: sendDate ?? this.sendDate,
      expiryDuration: expiryDuration ?? this.expiryDuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
