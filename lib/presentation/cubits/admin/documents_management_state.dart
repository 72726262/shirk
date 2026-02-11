import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/document_model.dart';

abstract class DocumentsManagementState extends Equatable {
  const DocumentsManagementState();

  @override
  List<Object?> get props => [];
}

class DocumentsManagementInitial extends DocumentsManagementState {}

class DocumentsManagementLoading extends DocumentsManagementState {}

class DocumentsManagementUploading extends DocumentsManagementState {}

class DocumentsManagementDownloading extends DocumentsManagementState {}

class DocumentsManagementLoaded extends DocumentsManagementState {
  final List<DocumentModel> documents;

  const DocumentsManagementLoaded({required this.documents});

  @override
  List<Object?> get props => [documents];
}

class DocumentUploadedSuccessfully extends DocumentsManagementState {
  final DocumentModel document;

  const DocumentUploadedSuccessfully({required this.document});

  @override
  List<Object?> get props => [document];
}

class DocumentSignedSuccessfully extends DocumentsManagementState {
  const DocumentSignedSuccessfully();
}

class DocumentDeletedSuccessfully extends DocumentsManagementState {
  const DocumentDeletedSuccessfully();
}

class DocumentDownloadReady extends DocumentsManagementState {
  final String url;

  const DocumentDownloadReady({required this.url});

  @override
  List<Object?> get props => [url];
}

class DocumentStatsLoaded extends DocumentsManagementState {
  final Map<String, int> stats;

  const DocumentStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class DocumentsManagementError extends DocumentsManagementState {
  final String message;

  const DocumentsManagementError({required this.message});

  @override
  List<Object?> get props => [message];
}
