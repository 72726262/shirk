import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// StorageService - Unified service for all file upload operations to Supabase Storage
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Bucket names constants
  static const String projectImagesBucket = 'project-images';
  static const String constructionMediaBucket = 'construction-media';
  static const String reportsBucket = 'reports';
  static const String documentsBucket = 'documents';
  static const String kycDocumentsBucket = 'kyc-documents';
  static const String avatarsBucket = 'avatars';

  // File size limits (in bytes)
  static const int projectImagesLimit = 10 * 1024 * 1024; // 10 MB
  static const int constructionMediaLimit = 50 * 1024 * 1024; // 50 MB
  static const int reportsLimit = 20 * 1024 * 1024; // 20 MB
  static const int documentsLimit = 10 * 1024 * 1024; // 10 MB
  static const int kycDocumentsLimit = 10 * 1024 * 1024; // 10 MB
  static const int avatarsLimit = 2 * 1024 * 1024; // 2 MB

  // Allowed MIME types
  static const List<String> imageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/jpg',
  ];
  static const List<String> videoTypes = [
    'video/mp4',
    'video/mpeg',
    'video/quicktime',
  ];
  static const List<String> documentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ];

  /// Upload project image to project-images bucket
  Future<String> uploadProjectImage(String filePath, String projectId) async {
    try {
      await _validateFile(filePath, imageTypes, projectImagesLimit);
      final fileName = '${projectId}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      
      // Compress image before upload
      final compressedFile = await _compressImage(filePath);
      
      final uploadPath = await _supabase.storage
          .from(projectImagesBucket)
          .upload(fileName, compressedFile ?? File(filePath));

      return _supabase.storage.from(projectImagesBucket).getPublicUrl(uploadPath);
    } catch (e) {
      throw Exception('فشل رفع صورة المشروع: ${e.toString()}');
    }
  }

  /// Upload construction media (photos/videos) to construction-media bucket
  Future<String> uploadConstructionMedia(
    String filePath,
    String projectId, {
    bool isVideo = false,
  }) async {
    try {
      final allowedTypes = isVideo ? videoTypes : imageTypes;
      await _validateFile(filePath, allowedTypes, constructionMediaLimit);

      final fileName = '${projectId}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      
      File? fileToUpload;
      if (!isVideo) {
        // Compress images only
        fileToUpload = await _compressImage(filePath);
      }

      final uploadPath = await _supabase.storage
          .from(constructionMediaBucket)
          .upload(fileName, fileToUpload ?? File(filePath));

      return _supabase.storage.from(constructionMediaBucket).getPublicUrl(uploadPath);
    } catch (e) {
      throw Exception('فشل رفع وسائط البناء: ${e.toString()}');
    }
  }

  /// Upload report to reports bucket
  Future<String> uploadReport(
    String filePath,
    String projectId,
    String reportType,
  ) async {
    try {
      await _validateFile(filePath, documentTypes, reportsLimit);

      final fileName = '${projectId}/${reportType}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';

      final uploadPath = await _supabase.storage
          .from(reportsBucket)
          .upload(fileName, File(filePath));

      return uploadPath;
    } catch (e) {
      throw Exception('فشل رفع التقرير: ${e.toString()}');
    }
  }

  /// Upload document to documents bucket
  Future<String> uploadDocument(
    String filePath,
    String userId,
    String documentType,
  ) async {
    try {
      final allowedTypes = [...documentTypes, ...imageTypes];
      await _validateFile(filePath, allowedTypes, documentsLimit);

      final fileName = '${userId}/${documentType}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';

      final uploadPath = await _supabase.storage
          .from(documentsBucket)
          .upload(fileName, File(filePath));

      return uploadPath;
    } catch (e) {
      throw Exception('فشل رفع المستند: ${e.toString()}');
    }
  }

  /// Upload KYC document to kyc-documents bucket
  Future<String> uploadKYCDocument(
    String filePath,
    String userId,
    String documentType,
  ) async {
    try {
      final allowedTypes = [...imageTypes, 'application/pdf'];
      await _validateFile(filePath, allowedTypes, kycDocumentsLimit);

      final fileName = '${userId}/${documentType}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';

      final uploadPath = await _supabase.storage
          .from(kycDocumentsBucket)
          .upload(fileName, File(filePath));

      return uploadPath;
    } catch (e) {
      throw Exception('فشل رفع مستند التحقق: ${e.toString()}');
    }
  }

  /// Upload avatar to avatars bucket
  Future<String> uploadAvatar(String filePath, String userId) async {
    try {
      await _validateFile(filePath, imageTypes, avatarsLimit);

      // Delete old avatar if exists
      try {
        final files = await _supabase.storage.from(avatarsBucket).list(path: userId);
        for (final file in files) {
          await _supabase.storage.from(avatarsBucket).remove(['${userId}/${file.name}']);
        }
      } catch (e) {
        // Ignore if no previous avatar exists
      }

      final fileName = '${userId}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      
      // Compress avatar image
      final compressedFile = await _compressImage(filePath, quality: 80);

      final uploadPath = await _supabase.storage
          .from(avatarsBucket)
          .upload(fileName, compressedFile ?? File(filePath));

      return _supabase.storage.from(avatarsBucket).getPublicUrl(uploadPath);
    } catch (e) {
      throw Exception('فشل رفع الصورة الشخصية: ${e.toString()}');
    }
  }

  /// Upload multiple files to a specific bucket
  Future<List<String>> uploadMultipleFiles(
    List<String> filePaths,
    String bucketName,
    String folder,
  ) async {
    try {
      final urls = <String>[];
      for (final filePath in filePaths) {
        final fileName = '${folder}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
        
        final uploadPath = await _supabase.storage
            .from(bucketName)
            .upload(fileName, File(filePath));

        final url = bucketName == projectImagesBucket ||
                bucketName == constructionMediaBucket ||
                bucketName == avatarsBucket
            ? _supabase.storage.from(bucketName).getPublicUrl(uploadPath)
            : uploadPath;

        urls.add(url);
      }
      return urls;
    } catch (e) {
      throw Exception('فشل رفع الملفات: ${e.toString()}');
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String bucketName, String filePath) async {
    try {
      await _supabase.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      throw Exception('فشل حذف الملف: ${e.toString()}');
    }
  }

  /// Get public URL for a file
  String getPublicUrl(String bucketName, String filePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(filePath);
  }

  /// Get signed URL for private files
  Future<String> getSignedUrl(
    String bucketName,
    String filePath, {
    int expiresIn = 3600,
  }) async {
    try {
      return await _supabase.storage
          .from(bucketName)
          .createSignedUrl(filePath, expiresIn);
    } catch (e) {
      throw Exception('فشل الحصول على رابط الملف: ${e.toString()}');
    }
  }

  /// Validate file type and size
  Future<void> _validateFile(
    String filePath,
    List<String> allowedTypes,
    int maxSize,
  ) async {
    final file = File(filePath);

    // Check if file exists
    if (!await file.exists()) {
      throw Exception('الملف غير موجود');
    }

    // Check file size
    final fileSize = await file.length();
    if (fileSize > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(0);
      throw Exception('حجم الملف يتجاوز الحد المسموح ($maxSizeMB ميجابايت)');
    }

    // Check file type based on extension
    final extension = path.extension(filePath).toLowerCase();
    final isAllowed = _isExtensionAllowed(extension, allowedTypes);

    if (!isAllowed) {
      throw Exception('نوع الملف غير مسموح');
    }
  }

  /// Check if file extension is allowed based on MIME types
  bool _isExtensionAllowed(String extension, List<String> allowedTypes) {
    final extensionMap = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.mp4': 'video/mp4',
      '.mpeg': 'video/mpeg',
      '.mov': 'video/quicktime',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    final mimeType = extensionMap[extension];
    return mimeType != null && allowedTypes.contains(mimeType);
  }

  /// Compress image before upload
  Future<File?> _compressImage(String filePath, {int quality = 85}) async {
    try {
      final file = File(filePath);
      final fileExtension = path.extension(filePath).toLowerCase();
      
      // Only compress JPEG and PNG
      if (fileExtension != '.jpg' && 
          fileExtension != '.jpeg' && 
          fileExtension != '.png') {
        return null;
      }

      final targetPath = path.join(
        path.dirname(filePath),
        'compressed_${path.basename(filePath)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      // If compression fails, return original file
      return null;
    }
  }

  /// Get bucket configuration
  Map<String, dynamic> getBucketConfig(String bucketName) {
    switch (bucketName) {
      case projectImagesBucket:
        return {
          'name': projectImagesBucket,
          'maxSize': projectImagesLimit,
          'allowedTypes': imageTypes,
          'isPublic': true,
        };
      case constructionMediaBucket:
        return {
          'name': constructionMediaBucket,
          'maxSize': constructionMediaLimit,
          'allowedTypes': [...imageTypes, ...videoTypes],
          'isPublic': true,
        };
      case reportsBucket:
        return {
          'name': reportsBucket,
          'maxSize': reportsLimit,
          'allowedTypes': documentTypes,
          'isPublic': false,
        };
      case documentsBucket:
        return {
          'name': documentsBucket,
          'maxSize': documentsLimit,
          'allowedTypes': [...documentTypes, ...imageTypes],
          'isPublic': false,
        };
      case kycDocumentsBucket:
        return {
          'name': kycDocumentsBucket,
          'maxSize': kycDocumentsLimit,
          'allowedTypes': [...imageTypes, 'application/pdf'],
          'isPublic': false,
        };
      case avatarsBucket:
        return {
          'name': avatarsBucket,
          'maxSize': avatarsLimit,
          'allowedTypes': imageTypes,
          'isPublic': true,
        };
      default:
        throw Exception('Bucket غير معروف');
    }
  }
}
