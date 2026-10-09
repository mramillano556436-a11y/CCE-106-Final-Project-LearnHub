import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class UploadedFile {
  final String url;
  final String name;
  final bool isImage;
  const UploadedFile({required this.url, required this.name, required this.isImage});
}

/// Uploads files to Cloudinary using an unsigned upload preset, so no API
/// secret is stored in the app.
class CloudinaryService {
  static const _maxBytes = 10 * 1024 * 1024; // Cloudinary free-plan limit

  static Future<UploadedFile> upload(Uint8List bytes, String fileName, {required String folder}) async {
    if (bytes.length > _maxBytes) {
      throw Exception('File is too large. The maximum size is 10 MB.');
    }
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/auto/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..fields['folder'] = 'learnhub/$folder'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final response = await http.Response.fromStream(await request.send());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final message = (body['error'] as Map?)?['message'] ?? 'Upload failed';
      throw Exception('Cloudinary: $message');
    }
    return UploadedFile(
      url: body['secure_url'] as String,
      name: fileName,
      isImage: body['resource_type'] == 'image',
    );
  }

  /// Lets the user pick an image and uploads it. Returns null if cancelled.
  static Future<UploadedFile?> pickAndUploadImage({required String folder}) =>
      _pickAndUpload(FileType.image, folder);

  /// Lets the user pick any file (PDF, docs, images) and uploads it.
  static Future<UploadedFile?> pickAndUploadFile({required String folder}) =>
      _pickAndUpload(FileType.any, folder);

  static Future<UploadedFile?> _pickAndUpload(FileType type, String folder) async {
    final file = await FilePicker.pickFile(type: type);
    if (file == null) return null;
    final bytes = await file.xFile.readAsBytes();
    return upload(bytes, file.name, folder: folder);
  }
}
