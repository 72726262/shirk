import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ChatStorageService {
  final SupabaseClient _client;

  ChatStorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Upload image bytes to chat-images bucket (cross-platform / web-compatible)
  Future<Map<String, dynamic>> uploadImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String chatId,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final ext = path.extension(fileName).isEmpty
          ? '.jpg'
          : path.extension(fileName);
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$userId/$chatId/$uniqueName';
      final mimeType = _getMimeType(fileName);

      await _client.storage
          .from('chat-images')
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      // Get signed URL (private bucket, valid for 1 year)
      final signedUrl = await _client.storage
          .from('chat-images')
          .createSignedUrl(storagePath, 31536000);

      return {
        'media_url': signedUrl,
        'file_name': uniqueName,
        'file_size': imageBytes.length,
        'storage_path': storagePath,
      };
    } catch (e) {
      throw Exception('فشل رفع الصورة: $e');
    }
  }

  /// Upload file bytes to chat-files bucket (cross-platform / web-compatible)
  Future<Map<String, dynamic>> uploadFileBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String chatId,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final ext = path.extension(fileName).isEmpty
          ? '.bin'
          : path.extension(fileName);
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$userId/$chatId/$uniqueName';
      final mimeType = _getMimeType(fileName);

      await _client.storage
          .from('chat-files')
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      // Get signed URL (private bucket, valid for 1 year)
      final signedUrl = await _client.storage
          .from('chat-files')
          .createSignedUrl(storagePath, 31536000);

      return {
        'media_url': signedUrl,
        'file_name': uniqueName,
        'file_size': fileBytes.length,
        'storage_path': storagePath,
      };
    } catch (e) {
      throw Exception('فشل رفع الملف: $e');
    }
  }

  String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.mpeg':
        return 'video/mpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
