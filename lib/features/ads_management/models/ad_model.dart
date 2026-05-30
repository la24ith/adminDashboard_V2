import 'dart:ui';

enum AdStatus { active, inactive, expired }

class AdModel {
  final int id;
  final String title;
  final String content;
  final String type;
  final String linkType;
  final String? linkUrl;
  final String position;
  final String? image;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int impressionCount;
  final int clickCount;
  final List<String> targetAudience;
  final int? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.linkType,
    this.linkUrl,
    required this.position,
    this.image,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.impressionCount = 0,
    this.clickCount = 0,
    required this.targetAudience,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'banner',
      linkType: json['link_type'] ?? 'external',
      linkUrl: json['link_url'],
      position: json['position'] ?? 'top',
      image: json['image'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      isActive: json['is_active'] ?? false,
      impressionCount: json['impression_count'] ?? 0,
      clickCount: json['click_count'] ?? 0,
      targetAudience: List<String>.from(json['target_audience'] ?? []),
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type,
      'link_type': linkType,
      'link_url': linkUrl,
      'position': position,
      'image': image,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'target_audience': targetAudience,
    };
  }

  AdStatus get status {
    final now = DateTime.now();
    if (!isActive) return AdStatus.inactive;
    if (endDate.isBefore(now)) return AdStatus.expired;
    return AdStatus.active;
  }

  String get statusText {
    switch (status) {
      case AdStatus.active:
        return 'نشط';
      case AdStatus.inactive:
        return 'غير نشط';
      case AdStatus.expired:
        return 'منتهي';
    }
  }

  Color get statusColor {
    switch (status) {
      case AdStatus.active:
        return const Color(0xFF10B981);
      case AdStatus.inactive:
        return const Color(0xFF94A3B8);
      case AdStatus.expired:
        return const Color(0xFFEF4444);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case AdStatus.active:
        return const Color(0xFFD1FAE5);
      case AdStatus.inactive:
        return const Color(0xFFF1F5F9);
      case AdStatus.expired:
        return const Color(0xFFFEE2E2);
    }
  }

  bool get hasImage => image != null && image!.isNotEmpty;
  bool get hasText => content.isNotEmpty;

  String get formattedStartDate {
    return '${startDate.day}/${startDate.month}/${startDate.year}';
  }

  String get formattedEndDate {
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }

  AdModel copyWith({
    int? id,
    String? title,
    String? content,
    String? type,
    String? linkType,
    String? linkUrl,
    String? position,
    String? image,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? impressionCount,
    int? clickCount,
    List<String>? targetAudience,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      linkType: linkType ?? this.linkType,
      linkUrl: linkUrl ?? this.linkUrl,
      position: position ?? this.position,
      image: image ?? this.image,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      impressionCount: impressionCount ?? this.impressionCount,
      clickCount: clickCount ?? this.clickCount,
      targetAudience: targetAudience ?? this.targetAudience,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
