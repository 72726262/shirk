import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/services/document_service.dart';

// States
abstract class DocumentsState extends Equatable {
  const DocumentsState();

  @override
  List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoading extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  final List<DocumentModel> documents;
  final Map<DocumentType, List<DocumentModel>> groupedDocuments;
  final Map<String, int> documentsCount;

  const DocumentsLoaded({
    required this.documents,
    required this.groupedDocuments,
    required this.documentsCount,
  });

  @override
  List<Object?> get props => [documents, groupedDocuments, documentsCount];
}

class DocumentUploading extends DocumentsState {
  final String message;

  const DocumentUploading(this.message);

  @override
  List<Object?> get props => [message];
}

class DocumentsError extends DocumentsState {
  final String message;

  const DocumentsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DocumentLoaded extends DocumentsState {
  final DocumentModel document;

  const DocumentLoaded(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentUploaded extends DocumentsState {
  final DocumentModel document;

  const DocumentUploaded(this.document);

  @override
  List<Object?> get props => [document];
}

// Cubit
class DocumentsCubit extends Cubit<DocumentsState> {
  final DocumentService _documentService;

  DocumentsCubit({DocumentService? documentService})
    : _documentService = documentService ?? DocumentService(),
      super(DocumentsInitial());

  Future<void> loadDocuments({
    required String userId,
    String? projectId,
    DocumentType? type,
  }) async {
    emit(DocumentsLoading());
    try {
      final documents = await _documentService.getUserDocuments(
        userId: userId,
        projectId: projectId,
        type: type,
      );

      final grouped = await _documentService.getDocumentsGroupedByType(userId);
      final count = await _documentService.getDocumentsCount(userId);

      emit(
        DocumentsLoaded(
          documents: documents,
          groupedDocuments: grouped,
          documentsCount: count,
        ),
      );
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> uploadDocument({
    required String userId,
    required String filePath,
    required DocumentType type,
    required String title,
    String? projectId,
    String? subscriptionId,
    String? description,
    List<String>? tags,
  }) async {
    emit(const DocumentUploading('جاري رفع المستند...'));
    try {
      await _documentService.uploadDocument(
        userId: userId,
        filePath: filePath,
        type: type,
        title: title,
        projectId: projectId,
        subscriptionId: subscriptionId,
        description: description,
        tags: tags,
      );

      // Reload documents after upload
      await loadDocuments(userId: userId);
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> signDocument({
    required String userId,
    required String documentId,
    required String signaturePath,
  }) async {
    emit(const DocumentUploading('جاري التوقيع...'));
    try {
      await _documentService.signDocument(
        documentId: documentId,
        signaturePath: signaturePath,
      );

      // Reload documents after signing
      await loadDocuments(userId: userId);
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> deleteDocument({
    required String userId,
    required String documentId,
  }) async {
    try {
      await _documentService.deleteDocument(documentId);

      // Reload documents after deletion
      await loadDocuments(userId: userId);
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> searchDocuments({
    required String userId,
    required String query,
  }) async {
    emit(DocumentsLoading());
    try {
      final documents = await _documentService.searchDocuments(
        userId: userId,
        query: query,
      );

      final grouped = await _documentService.getDocumentsGroupedByType(userId);
      final count = await _documentService.getDocumentsCount(userId);

      emit(
        DocumentsLoaded(
          documents: documents,
          groupedDocuments: grouped,
          documentsCount: count,
        ),
      );
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> loadDocument(String documentId) async {
    emit(DocumentsLoading());
    try {
      final document = await _documentService.getDocumentById(documentId);
      emit(DocumentLoaded(document));
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> refreshDocuments(String userId) async {
    await loadDocuments(userId: userId);
  }

  // Alias for backward compatibility
  Future<void> loadUserDocuments(String userId) async {
    await loadDocuments(userId: userId);
  }

  Future<void> downloadDocument(String documentId) async {
    // Implement download logic
  }

  Future<void> shareDocument(String documentId) async {
    // Implement share logic
  }
}
