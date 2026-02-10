import 'package:equatable/equatable.dart';

enum DocumentType {
  contract,
  invoice,
  receipt,
  report,
  certificate,
  kyc,
  other;

  String toJson() => name;
  
  static DocumentType fromJson(String value) {
    // Handle legacy 'id_card' mapping
    if (value == 'id_card' || value == 'idCard') {
      return DocumentType.kyc;
    }
    return DocumentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DocumentType.other,
    );
  }
  
  // Alias for backwards compatibility
  static DocumentType get idCard => DocumentType.kyc;
  
  String get displayName {
    switch (this) {
      case DocumentType.contract:
        return 'عقد';
      case DocumentType.invoice:
        return 'فاتورة';
      case DocumentType.receipt:
        return 'إيصال';
      case DocumentType.report:
        return 'تقرير';
      case DocumentType.certificate:
        return 'شهادة';
      case DocumentType.kyc:
        return 'هوية';
      case DocumentType.other:
        return 'أخرى';
    }
  }
}

class DocumentModel extends Equatable {
  final String id;
  final String userId;
  final String? projectId;
  final String? subscriptionId;
  final String title;
  final String? titleAr;
  final String? description;
  final DocumentType type;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String? uploadedBy;
  final bool requiresSignature;
  final bool isSigned;
  final DateTime? signedAt;
  final String? signatureUrl;
  final DateTime createdAt;

  const DocumentModel({
    required this.id,
    required this.userId,
    this.projectId,
    this.subscriptionId,
    required this.title,
    this.titleAr,
    this.description,
    this.type = DocumentType.other,
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 0,
    this.mimeType = 'application/pdf',
    this.uploadedBy,
    this.requiresSignature = false,
    this.isSigned = false,
    this.signedAt,
    this.signatureUrl,
    required this.createdAt,
    this.localPath,
  });

  final String? localPath;

  // Computed properties
  String get category => type.name;
  DateTime get uploadedAt => createdAt;
  String get displayTitle => titleAr ?? title;
  bool get isPdf => mimeType.contains('pdf');
  bool get isImage => mimeType.contains('image');

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      type: json['type'] != null
          ? DocumentType.fromJson(json['type'] as String)
          : DocumentType.other,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      uploadedBy: json['uploaded_by'] as String?,
      requiresSignature: json['requires_signature'] as bool? ?? false,
      isSigned: json['is_signed'] as bool? ?? false,
      signedAt: json['signed_at'] != null
          ? DateTime.parse(json['signed_at'] as String)
          : null,
      signatureUrl: json['signature_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'subscription_id': subscriptionId,
      'title': title,
      'title_ar': titleAr,
      'description': description,
      'type': type.toJson(),
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_by': uploadedBy,
      'requires_signature': requiresSignature,
      'is_signed': isSigned,
      'signed_at': signedAt?.toIso8601String(),
      'signature_url': signatureUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? subscriptionId,
    String? title,
    String? titleAr,
    String? description,
    DocumentType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        projectId,
        subscriptionId,
        title,
        titleAr,
        description,
        type,
        fileUrl,
        fileName,
        fileSize,
        mimeType,
        uploadedBy,
        createdAt,
        localPath,
      ];
}
