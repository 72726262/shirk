import 'package:equatable/equatable.dart';

enum ContractStatus {
  draft,
  pendingSignature,
  signed,
  executed,
  terminated,
  expired,
}

class ContractModel extends Equatable {
  final String id;
  final String? templateId;
  final String userId;
  final String? projectId;
  final String? subscriptionId;
  final String contractNumber;
  final String title;
  final String content;
  final Map<String, dynamic> terms;
  final List<dynamic> paymentSchedule;
  final ContractStatus status;
  final DateTime? clientSignedAt;
  final String? clientSignatureUrl;
  final String? clientIp;
  final DateTime? adminSignedAt;
  final String? adminSignatureUrl;
  final String? adminUserId;
  final String? pdfUrl;
  final DateTime? effectiveDate;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractModel({
    required this.id,
    this.templateId,
    required this.userId,
    this.projectId,
    this.subscriptionId,
    required this.contractNumber,
    required this.title,
    required this.content,
    this.terms = const {},
    this.paymentSchedule = const [],
    required this.status,
    this.clientSignedAt,
    this.clientSignatureUrl,
    this.clientIp,
    this.adminSignedAt,
    this.adminSignatureUrl,
    this.adminUserId,
    this.pdfUrl,
    this.effectiveDate,
    this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as String,
      templateId: json['template_id'] as String?,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      contractNumber: json['contract_number'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      terms: json['terms'] != null
          ? Map<String, dynamic>.from(json['terms'] as Map)
          : {},
      paymentSchedule: json['payment_schedule'] != null
          ? List.from(json['payment_schedule'] as List)
          : [],
      status: ContractStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String).replaceAll('_', ''),
        orElse: () => ContractStatus.draft,
      ),
      clientSignedAt: json['client_signed_at'] != null
          ? DateTime.parse(json['client_signed_at'] as String)
          : null,
      clientSignatureUrl: json['client_signature_url'] as String?,
      clientIp: json['client_ip'] as String?,
      adminSignedAt: json['admin_signed_at'] != null
          ? DateTime.parse(json['admin_signed_at'] as String)
          : null,
      adminSignatureUrl: json['admin_signature_url'] as String?,
      adminUserId: json['admin_user_id'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      effectiveDate: json['effective_date'] != null
          ? DateTime.parse(json['effective_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template_id': templateId,
      'user_id': userId,
      'project_id': projectId,
      'subscription_id': subscriptionId,
      'contract_number': contractNumber,
      'title': title,
      'content': content,
      'terms': terms,
      'payment_schedule': paymentSchedule,
      'status': status.name,
      'client_signed_at': clientSignedAt?.toIso8601String(),
      'client_signature_url': clientSignatureUrl,
      'client_ip': clientIp,
      'admin_signed_at': adminSignedAt?.toIso8601String(),
      'admin_signature_url': adminSignatureUrl,
      'admin_user_id': adminUserId,
      'pdf_url': pdfUrl,
      'effective_date': effectiveDate?.toIso8601String().split('T')[0],
      'expiry_date': expiryDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isSigned => status == ContractStatus.signed;
  bool get isExecuted => status == ContractStatus.executed;
  bool get isPendingSignature => status == ContractStatus.pendingSignature;
  bool get isActive => status == ContractStatus.signed || status == ContractStatus.executed;

  @override
  List<Object?> get props => [
        id,
        templateId,
        userId,
        projectId,
        subscriptionId,
        contractNumber,
        title,
        content,
        terms,
        paymentSchedule,
        status,
        clientSignedAt,
        clientSignatureUrl,
        clientIp,
        adminSignedAt,
        adminSignatureUrl,
        adminUserId,
        pdfUrl,
        effectiveDate,
        expiryDate,
        createdAt,
        updatedAt,
      ];
}
