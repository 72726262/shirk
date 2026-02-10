import 'package:equatable/equatable.dart';

enum KycStatus {
  pending,
  underReview,
  approved,
  rejected;

  String toJson() => name;
  
  static KycStatus fromJson(String value) {
    return KycStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => KycStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case KycStatus.pending:
        return 'قيد الانتظار';
      case KycStatus.underReview:
        return 'قيد المراجعة';
      case KycStatus.approved:
        return 'موافق عليه';
      case KycStatus.rejected:
        return 'مرفوض';
    }
  }
}

enum UserRole {
  client,
  admin,
  superAdmin;

  String toJson() => name;
  
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.client,
    );
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
  final UserRole role;
  
  // KYC Fields
  final KycStatus kycStatus;
  final DateTime? kycSubmittedAt;
  final DateTime? kycReviewedAt;
  final String? kycRejectionReason;
  final String? idFrontUrl;
  final String? idBackUrl;
  final String? selfieUrl;
  final String? incomeProofUrl;
  
  // Timestamps
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
    this.role = UserRole.client,
    this.kycStatus = KycStatus.pending,
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
      role: json['role'] != null
          ? UserRole.fromJson(json['role'] as String)
          : UserRole.client,
      kycStatus: json['kyc_status'] != null
          ? KycStatus.fromJson(json['kyc_status'] as String)
          : KycStatus.pending,
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
      'role': role.toJson(),
      'kyc_status': kycStatus.toJson(),
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

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? nationalId,
    DateTime? dateOfBirth,
    String? avatarUrl,
    UserRole? role,
    KycStatus? kycStatus,
    DateTime? kycSubmittedAt,
    DateTime? kycReviewedAt,
    String? kycRejectionReason,
    String? idFrontUrl,
    String? idBackUrl,
    String? selfieUrl,
    String? incomeProofUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      kycStatus: kycStatus ?? this.kycStatus,
      kycSubmittedAt: kycSubmittedAt ?? this.kycSubmittedAt,
      kycReviewedAt: kycReviewedAt ?? this.kycReviewedAt,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      incomeProofUrl: incomeProofUrl ?? this.incomeProofUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
