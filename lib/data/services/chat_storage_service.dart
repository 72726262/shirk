import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ChatStorageService {
  final SupabaseClient _client;

  ChatStorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Upload image to chat-images bucket
  Future<Map<String, dynamic>> uploadImage({
    required File imageFile,
    required String chatId,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final ext = path.extension(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$userId/$chatId/$fileName';

      // 1. Upload file
      final bytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);

      await _client.storage
          .from('chat-images')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      // 2. Get public URL
      final publicUrl = _client.storage
          .from('chat-images')
          .getPublicUrl(storagePath);

      // 3. Get file metadata
      final fileSize = await imageFile.length();

      return {
        'media_url': publicUrl,

        'file_name': fileName,
        'file_size': fileSize,
        'storage_path': storagePath,
        'media_metadata': {
          'width': 0, // ideally get image dimensions
          'height': 0,
          'bucket': 'chat-images',
        },
      };
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload file to chat-files bucket
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String chatId,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final ext = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$userId/$chatId/$fileName';

      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(file.path);

      await _client.storage
          .from('chat-files')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: mimeType,
            ),
          );

      final publicUrl = _client.storage
          .from('chat-files')
          .getPublicUrl(storagePath);
      final fileSize = await file.length();

      return {
        'media_url': publicUrl,
        'media_url': publicUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'storage_path': storagePath,
        'media_metadata': {
          'bucket': 'chat-files',
          'extension': path.extension(file.path),
        },
      };
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload video (uses chat-files or chat-images depending on size/pref, but typically chat-files or separate bucket)
  /// For now we'll use chat-files for videos or chat-images if small.
  /// Let's use chat-images for consistency if it allows video mimes, otherwise chat-files.
  /// Our migration said chat-images allows 'image/*', and chat-files allows documents.
  /// We should probably update bucket config if we want videos in chat-images, or put them in chat-files.
  /// Let's put videos in chat-files for now.
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String chatId,
    required String userId,
    File? thumbnailFile,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload video
      final videoData = await uploadFile(
        file: videoFile,
        chatId: chatId,
        userId: userId,
        onProgress: onProgress,
      );

      String? thumbnailUrl;
      if (thumbnailFile != null) {
        final thumbData = await uploadImage(
          imageFile: thumbnailFile,
          chatId: chatId,
          userId: userId,
        );
        thumbnailUrl = thumbData['media_url'];
      }

      return {
        ...videoData,
        'thumbnail_url': thumbnailUrl,
        'media_metadata': {
          ...videoData['media_metadata'] as Map<String, dynamic>,
          'type': 'video',
          'duration': 0, // ideally get duration
        },
      };
    } catch (e) {
      throw Exception('Failed to upload video: $e');
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
