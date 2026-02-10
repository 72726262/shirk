// data/models/user_model.dart
import 'package:equatable/equatable.dart';

enum KYCStatus {
  pending,
  underReview,
  approved,
  rejected;

  static KYCStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return KYCStatus.pending;
      case 'under_review':
        return KYCStatus.underReview;
      case 'approved':
        return KYCStatus.approved;
      case 'rejected':
        return KYCStatus.rejected;
      default:
        return KYCStatus.pending;
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? nationalId;
  final DateTime? dateOfBirth;
  final String? avatarUrl;
  final String role;
  final KYCStatus kycStatus;
  final DateTime? kycSubmittedAt;
  final DateTime? kycReviewedAt;
  final String? kycRejectionReason;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? selfieUrl;
  final String? incomeProofUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.nationalId,
    this.dateOfBirth,
    this.avatarUrl,
    this.role = 'client',
    this.kycStatus = KYCStatus.pending,
    this.kycSubmittedAt,
    this.kycReviewedAt,
    this.kycRejectionReason,
    this.idFrontUrl,
    this.idBackUrl,
    this.selfieUrl,
    this.incomeProofUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      nationalId: json['national_id'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'client',
      kycStatus: json['kyc_status'] != null
          ? KYCStatus.fromString(json['kyc_status'] as String)
          : KYCStatus.pending,
      kycSubmittedAt: json['kyc_submitted_at'] != null
          ? DateTime.parse(json['kyc_submitted_at'] as String)
          : null,
      kycReviewedAt: json['kyc_reviewed_at'] != null
          ? DateTime.parse(json['kyc_reviewed_at'] as String)
          : null,
      kycRejectionReason: json['kyc_rejection_reason'] as String?,
      idFrontUrl: json['id_front_url'] as String?,
      idBackUrl: json['id_back_url'] as String?,
      selfieUrl: json['selfie_url'] as String?,
      incomeProofUrl: json['income_proof_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'national_id': nationalId,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'avatar_url': avatarUrl,
      'role': role,
      'kyc_status': kycStatus.toString().split('.').last,
      'kyc_submitted_at': kycSubmittedAt?.toIso8601String(),
      'kyc_reviewed_at': kycReviewedAt?.toIso8601String(),
      'kyc_rejection_reason': kycRejectionReason,
      'id_front_url': idFrontUrl,
      'id_back_url': idBackUrl,
      'selfie_url': selfieUrl,
      'income_proof_url': incomeProofUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phone,
    nationalId,
    dateOfBirth,
    avatarUrl,
    role,
    kycStatus,
    kycSubmittedAt,
    kycReviewedAt,
    kycRejectionReason,
    idFrontUrl,
    idBackUrl,
    selfieUrl,
    incomeProofUrl,
    createdAt,
    updatedAt,
  ];
}
