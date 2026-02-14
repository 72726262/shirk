import 'package:bloc/bloc.dart';
import 'package:mmm/data/services/document_service.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_state.dart';

class DocumentsManagementCubit extends Cubit<DocumentsManagementState> {
  final DocumentService _documentService = DocumentService();

  DocumentsManagementCubit() : super(DocumentsManagementInitial());

  Future<void> loadDocuments({String? userId, String? type}) async {
    try {
      emit(DocumentsManagementLoading());
      
      // if (userId == null) {
      //   emit(DocumentsManagementError(message: 'معرف المستخدم مطلوب'));
      //   return;
      // }

      // getUserDocuments accepts userId and optional type
      DocumentType? documentType;
      if (type != null) {
        documentType = DocumentType.values.firstWhere(
          (e) => e.name == type,
          orElse: () => DocumentType.other,
        );
      }

      final documents = await _documentService.getUserDocuments(
        userId: userId,
        type: documentType,
      );

      emit(DocumentsManagementLoaded(documents: documents));
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في تحميل المستندات: ${e.toString()}'));
    }
  }

  Future<void> uploadDocument({
    required String userId,
    required String title,
    required DocumentType type,
    required String filePath,
    String? description,
    String? projectId,
    String? subscriptionId,
  }) async {
    try {
      emit(DocumentsManagementUploading());

      final document = await _documentService.uploadDocument(
        userId: userId,
        title: title,
        type: type,
        filePath: filePath,
        description: description,
        projectId: projectId,
        subscriptionId: subscriptionId,
      );

      emit(DocumentUploadedSuccessfully(document: document));
      loadDocuments(userId: userId);
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في رفع المستند: ${e.toString()}'));
    }
  }

  Future<void> updateDocument({
    required String documentId,
    String? title,
    String? description,
    DocumentType? type,
    String? projectId,
  }) async {
    try {
      emit(DocumentsManagementUploading());

      final document = await _documentService.updateDocument(
        documentId: documentId,
        title: title,
        description: description,
        type: type,
        projectId: projectId,
      );

      emit(DocumentUploadedSuccessfully(document: document));
      loadDocuments();
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في تعديل المستند: ${e.toString()}'));
    }
  }

  Future<void> deleteDocument(String documentId, {String? userId}) async {
    try {
      await _documentService.deleteDocument(documentId);
      
      if (userId != null) {
        loadDocuments(userId: userId);
      }
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في حذف المستند: ${e.toString()}'));
    }
  }

  Future<void> signDocument({
    required String documentId,
    required String signaturePath,
    String? userId,
  }) async {
    try {
      await _documentService.signDocument(
        documentId: documentId,
        signaturePath: signaturePath,
      );
      
      if (userId != null) {
        loadDocuments(userId: userId);
      }
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في توقيع المستند: ${e.toString()}'));
    }
  }

  Future<void> downloadDocument(String documentId) async {
    try {
      final url = await _documentService.getDocumentDownloadUrl(documentId);
      emit(DocumentDownloadReady(url: url));
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في تحميل المستند: ${e.toString()}'));
    }
  }

  Future<void> loadDocumentStats(String userId) async {
    try {
      final stats = await _documentService.getDocumentsCount(userId);
      // You can create a DocumentStatsLoaded state if needed
      final documents = await _documentService.getUserDocuments(userId: userId);
      emit(DocumentsManagementLoaded(documents: documents));
    } catch (e) {
      emit(DocumentsManagementError(message: 'فشل في تحميل إحصائيات المستندات'));
    }
  }
}
