import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class DocumentRepository {
  final SupabaseService _supabaseService;
  
  DocumentRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get user documents
  Future<List<DocumentModel>> getUserDocuments({
    required String userId,
    DocumentType? type,
    String? projectId,
    String? subscriptionId,
  }) async {
    try {
      var query = _client
          .from('documents')
          .select('*')
          .eq('user_id', userId);

      if (type != null) {
        query = query.eq('document_type', type.name);
      }

      if (projectId != null) {
        query = query.eq('project_id', projectId);
      }

      if (subscriptionId != null) {
        query = query.eq('subscription_id', subscriptionId);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل المستندات: ${e.toString()}');
    }
  }

  // Get document by ID
  Future<DocumentModel> getDocumentById(String documentId) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .eq('id', documentId)
          .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل المستند: ${e.toString()}');
    }
  }

  // Upload document
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
      // Upload file to Supabase Storage
      final fileUrl = await _supabaseService.uploadFile(
        bucketName: 'documents',
        path: 'users/$userId/${type.name}/${DateTime.now().millisecondsSinceEpoch}_${title.replaceAll(' ', '_')}.pdf',
        filePath: filePath,
      );

      // Get file size (you would need to implement this in your app)
      final fileSize = 0; // TODO: Get actual file size

      // Create document record
      final documentData = {
        'user_id': userId,
        'project_id': projectId,
        'subscription_id': subscriptionId,
        'document_type': type.name,
        'title': title,
        'file_url': fileUrl,
        'file_size': fileSize,
        'file_type': 'application/pdf',
        'status': 'unsigned',
        'description': description,
        'tags': tags ?? [],
        'version': 1,
      };

      final response = await _client
          .from('documents')
          .insert(documentData)
          .select()
          .single();

      return DocumentModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في رفع المستند: ${e.toString()}');
    }
  }

  // Sign document
  Future<DocumentModel> signDocument({
    required String documentId,
    required String signatureData,
  }) async {
    try {
      // Upload signature
      final doc = await getDocumentById(documentId);
      final signatureUrl = await _supabaseService.uploadFile(
        bucketName: 'signatures',
        path: 'documents/$documentId/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        filePath: signatureData,
      );

      // Update document
      await _client
          .from('documents')
          .update({
            'status': 'signed',
            'signed_at': DateTime.now().toIso8601String(),
            'signature_url': signatureUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', documentId);

      return await getDocumentById(documentId);
    } catch (e) {
      throw Exception('خطأ في توقيع المستند: ${e.toString()}');
    }
  }

  // Download document
  Future<String> getDocumentDownloadUrl(String documentId) async {
    try {
      final doc = await getDocumentById(documentId);
      return doc.fileUrl;
    } catch (e) {
      throw Exception('خطأ في تحميل رابط المستند: ${e.toString()}');
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      final doc = await getDocumentById(documentId);

      // Delete from storage
      if (doc.fileUrl.isNotEmpty) {
        await _supabaseService.deleteFile(doc.fileUrl);
      }

      // Delete signature if exists
      if (doc.signatureUrl != null && doc.signatureUrl!.isNotEmpty) {
        await _supabaseService.deleteFile(doc.signatureUrl!);
      }

      // Delete from database
      await _client
          .from('documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      throw Exception('خطأ في حذف المستند: ${e.toString()}');
    }
  }

  // Get documents count by type
  Future<Map<DocumentType, int>> getDocumentsCountByType(String userId) async {
    try {
      final documents = await getUserDocuments(userId: userId);
      
      final counts = <DocumentType, int>{};
      for (var type in DocumentType.values) {
        counts[type] = documents.where((d) => d.type == type).length;
      }

      return counts;
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات المستندات: ${e.toString()}');
    }
  }

  // Search documents
  Future<List<DocumentModel>> searchDocuments({
    required String userId,
    required String query,
  }) async {
    try {
      final response = await _client
          .from('documents')
          .select()
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DocumentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في البحث عن المستندات: ${e.toString()}');
    }
  }
}
