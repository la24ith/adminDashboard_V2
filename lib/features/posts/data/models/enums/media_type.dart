enum MediaType {
  image,
  video,
  audio,
  other;

  String get arabicName {
    switch (this) {
      case MediaType.image:
        return 'صورة';
      case MediaType.video:
        return 'فيديو';
      case MediaType.audio:
        return 'صوت';
      default:
        return 'ملف';
    }
  }
}
