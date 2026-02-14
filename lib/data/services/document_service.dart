import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/repositories/document_repository.dart';
import 'package:mmm/data/services/storage_service.dart';

/// Document Service - Handles document management business logic
class DocumentService {
  final DocumentRepository _documentRepository;
  final StorageService _storageService;

  DocumentService({
    DocumentRepository? documentRepository,
    StorageService? storageService,
  })  : _documentRepository = documentRepository ?? DocumentRepository(),
        _storageService = storageService ?? StorageService();

  // Get user documents with optional filters
  Future<List<DocumentModel>> getUserDocuments({
    String? userId,
    String? projectId,
    DocumentType? type,
  }) async {
    try {
      return await _documentRepository.getUserDocuments(
        userId: userId,
        projectId: projectId,
        type: type,
      );
    } catch (e) {
      throw Exception('فشل تحميل المستندات: ${e.toString()}');
    }
  }

  // Get document by ID
  Future<DocumentModel> getDocumentById(String documentId) async {
    try {
      return await _documentRepository.getDocumentById(documentId);
    } catch (e) {
      throw Exception('فشل تحميل المستند: ${e.toString()}');
    }
  }

  // Upload document with validation
  Future<DocumentModel> uploadDocument({
    required String userId,
    required String filePath,
    required DocumentType type,
    required String title,
    String? projectId,
    String? subscriptionId,
    String? description,
    List<String>? tags,
  }) async {
    try {
      // Upload file to appropriate bucket based on type
      String fileUrl;
      if (type == DocumentType.kyc) {
        // Upload to kyc-documents bucket
        fileUrl = await _storageService.uploadKYCDocument(
          filePath,
          userId,
          'kyc',
        );
      } else {
        // Upload to documents bucket
        fileUrl = await _storageService.uploadDocument(
          filePath,
          userId,
          type.name,
        );
      }

      return await _documentRepository.uploadDocument(
        userId: userId,
        filePath: fileUrl,
        type: type,
        title: title,
        projectId: projectId,
        subscriptionId: subscriptionId,
        description: description,
        tags: tags,
      );
    } catch (e) {
      throw Exception('فشل رفع المستند: ${e.toString()}');
    }
  }

  // Update document metadata
  Future<DocumentModel> updateDocument({
    required String documentId,
    String? title,
    String? description,
    String? projectId,
    DocumentType? type,
  }) async {
    try {
      return await _documentRepository.updateDocument(
        documentId: documentId,
        title: title,
        description: description,
        projectId: projectId,
        type: type,
      );
    } catch (e) {
      throw Exception('فشل تحديث المستند: ${e.toString()}');
    }
  }

  // Sign document with signature upload
  Future<DocumentModel> signDocument({
    required String documentId,
    required String signaturePath,
  }) async {
    try {
      return await _documentRepository.signDocument(
        documentId: documentId,
        signatureData: signaturePath,
      );
    } catch (e) {
      throw Exception('فشل توقيع المستند: ${e.toString()}');
    }
  }

  // Download document
  Future<String> getDocumentDownloadUrl(String documentId) async {
    try {
      return await _documentRepository.getDocumentDownloadUrl(documentId);
    } catch (e) {
      throw Exception('فشل تحميل المستند: ${e.toString()}');
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentRepository.deleteDocument(documentId);
    } catch (e) {
      throw Exception('فشل حذف المستند: ${e.toString()}');
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments({
    required String userId,
    required String query,
  }) async {
    try {
      return await _documentRepository.searchDocuments(
        userId: userId,
        query: query,
      );
    } catch (e) {
      throw Exception('فشل البحث في المستندات: ${e.toString()}');
    }
  }

  // Get documents count by type (for dashboard)
  Future<Map<String, int>> getDocumentsCount(String userId) async {
    try {
      final counts = await _documentRepository.getDocumentsCountByType(userId);
      // Convert Map<DocumentType, int> to Map<String, int>
      return counts.map((key, value) => MapEntry(key.name, value));
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المستندات: ${e.toString()}');
    }
  }

  // Get documents grouped by type
  Future<Map<DocumentType, List<DocumentModel>>> getDocumentsGroupedByType(
    String userId,
  ) async {
    try {
      final documents = await _documentRepository.getUserDocuments(
        userId: userId,
      );

      final grouped = <DocumentType, List<DocumentModel>>{};
      for (final doc in documents) {
        grouped.putIfAbsent(doc.type, () => []).add(doc);
      }

      return grouped;
    } catch (e) {
      throw Exception('فشل تحميل المستندات: ${e.toString()}');
    }
  }
}
