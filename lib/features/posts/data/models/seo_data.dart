import 'package:equatable/equatable.dart';

class SeoData extends Equatable {
  final String metaTitle;
  final String metaDescription;
  final String canonicalUrl;
  final String openGraphImage;
  final List<String> keywords;

  const SeoData({
    this.metaTitle = '',
    this.metaDescription = '',
    this.canonicalUrl = '',
    this.openGraphImage = '',
    this.keywords = const [],
  });

  factory SeoData.fromJson(Map<String, dynamic> json) {
    return SeoData(
      metaTitle: json['meta_title'] ?? '',
      metaDescription: json['meta_description'] ?? '',
      canonicalUrl: json['canonical_url'] ?? '',
      openGraphImage: json['og_image'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'meta_title': metaTitle,
        'meta_description': metaDescription,
        'canonical_url': canonicalUrl,
        'og_image': openGraphImage,
        'keywords': keywords,
      };

  SeoData copyWith({
    String? metaTitle,
    String? metaDescription,
    String? canonicalUrl,
    String? openGraphImage,
    List<String>? keywords,
  }) {
    return SeoData(
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      openGraphImage: openGraphImage ?? this.openGraphImage,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  List<Object?> get props =>
      [metaTitle, metaDescription, canonicalUrl, openGraphImage, keywords];
}
