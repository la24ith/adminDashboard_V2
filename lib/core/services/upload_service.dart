import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../constants/api_constants.dart';

class MediaUploadService {
  final http.Client _client = http.Client();

  Future<UploadResult> uploadFile(
    File file, {
    Function(double)? onProgress,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/media/upload');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType.parse(mimeType),
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UploadResult(
        id: data['id'].toString(),
        url: data['url'] ?? data['path'],
      );
    } else {
      throw Exception('فشل الرفع: ${response.statusCode} - ${response.body}');
    }
  }

  void dispose() => _client.close();
}

class UploadResult {
  final String id;
  final String url;
  UploadResult({required this.id, required this.url});
}
