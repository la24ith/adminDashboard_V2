class PostValidators {
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'العنوان مطلوب';
    }
    if (value.length < 3) {
      return 'العنوان يجب أن يكون 3 أحرف على الأقل';
    }
    if (value.length > 150) {
      return 'العنوان طويل جداً (الحد الأقصى 150 حرف)';
    }
    return null;
  }

  static String? validateContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'المحتوى مطلوب';
    }
    if (value.length < 10) {
      return 'المحتوى يجب أن يكون 10 أحرف على الأقل';
    }
    return null;
  }

  static bool validateFileSize(int sizeInBytes, int maxMB) {
    final sizeInMB = sizeInBytes / (1024 * 1024);
    return sizeInMB <= maxMB;
  }

  static String? validateScheduledDate(DateTime? date) {
    if (date != null && date.isBefore(DateTime.now())) {
      return 'لا يمكن جدولة المنشور في الماضي';
    }
    return null;
  }
}
