import 'dart:io';
import 'enums/media_type.dart';
import '../../../../../core/constants/api_constants.dart';

enum UploadStatus { pending, uploading, completed, failed }

class MediaItem {
  final String? id;
  final MediaType type;
  final File? localFile;
  final String? remoteUrl;
  final String? remoteId;
  final UploadStatus status;
  final double progress;
  final String? error;

  MediaItem({
    this.id,
    required this.type,
    this.localFile,
    this.remoteUrl,
    this.remoteId,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      type: MediaType.values.firstWhere((e) => e.name == json['type']),
      remoteUrl: json['remoteUrl'],
      remoteId: json['remoteId'],
      status: UploadStatus.values.firstWhere((e) => e.name == json['status']),
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'remoteUrl': remoteUrl,
        'remoteId': remoteId,
        'status': status.name,
        'progress': progress,
      };

  String get displayName =>
      localFile?.path.split('/').last ?? remoteUrl ?? 'ملف';
  String? get fullUrl =>
      remoteUrl != null ? ApiConstants.getFullMediaUrl(remoteUrl!) : null;

  MediaItem copyWith({
    String? id,
    MediaType? type,
    File? localFile,
    String? remoteUrl,
    String? remoteId,
    UploadStatus? status,
    double? progress,
    String? error,
  }) {
    return MediaItem(
      id: id ?? this.id,
      type: type ?? this.type,
      localFile: localFile ?? this.localFile,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      remoteId: remoteId ?? this.remoteId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }
}
