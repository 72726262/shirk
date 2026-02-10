import 'package:equatable/equatable.dart';

enum SubscriptionStatus {
  pending,
  active,
  completed,
  cancelled;

  String toJson() => name;
  
  static SubscriptionStatus fromJson(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SubscriptionStatus.pending,
    );
  }
  
  String get displayName {
    switch (this) {
      case SubscriptionStatus.pending:
        return 'قيد الانتظار';
      case SubscriptionStatus.active:
        return 'نشط';
      case SubscriptionStatus.completed:
        return 'مكتمل';
      case SubscriptionStatus.cancelled:
        return 'ملغي';
    }
  }
}

class SubscriptionModel extends Equatable {
  final String id;
  final String userId;
  final String projectId;
  final String unitId;
  final double shareAmount;
  final double paidAmount;
  final SubscriptionStatus status;
  final DateTime? joinedAt;
  final DateTime? completedAt;
  final String? contractId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.unitId,
    required this.shareAmount,
    this.paidAmount = 0.0,
    this.status = SubscriptionStatus.pending,
    this.joinedAt,
    this.completedAt,
    this.contractId,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => shareAmount - paidAmount;
  double get paidPercentage => (paidAmount / shareAmount) * 100;
  double get investmentAmount => shareAmount;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      unitId: json['unit_id'] as String,
      shareAmount: (json['share_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] != null
          ? SubscriptionStatus.fromJson(json['status'] as String)
          : SubscriptionStatus.pending,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      contractId: json['contract_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'unit_id': unitId,
      'share_amount': shareAmount,
      'paid_amount': paidAmount,
      'status': status.toJson(),
      'joined_at': joinedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'contract_id': contractId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? unitId,
    double? shareAmount,
    double? paidAmount,
    SubscriptionStatus? status,
    DateTime? joinedAt,
    DateTime? completedAt,
    String? contractId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      unitId: unitId ?? this.unitId,
      shareAmount: shareAmount ?? this.shareAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
      contractId: contractId ?? this.contractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        projectId,
        unitId,
        shareAmount,
        paidAmount,
        status,
        joinedAt,
        completedAt,
        contractId,
        createdAt,
        updatedAt,
      ];
}
