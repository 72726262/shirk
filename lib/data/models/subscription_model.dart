import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';

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
  final double investmentAmount; // Renamed from shareAmount to match schema
  final double paidAmount;
  final SubscriptionStatus status;
  final DateTime? joinedAt;
  final DateTime? completedAt;
  final String? contractId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? projectName;
  final ProjectModel? project;
  final UnitModel? unit;
  final double? downPayment;
  final int installmentsCount;
  final int installmentsPaid;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.projectId,
    required this.unitId,
    required this.investmentAmount,
    this.paidAmount = 0.0,
    this.status = SubscriptionStatus.pending,
    this.joinedAt,
    this.completedAt,
    this.contractId,
    required this.createdAt,
    required this.updatedAt,
    this.projectName,
    this.project,
    this.unit,
    this.downPayment,
    this.installmentsCount = 0,
    this.installmentsPaid = 0,
  });

  double get remainingAmount => investmentAmount - paidAmount;
  double get paidPercentage => (investmentAmount > 0) ? (paidAmount / investmentAmount) * 100 : 0;
  
  // Getter for backward compatibility if needed, though better to use investmentAmount
  double get shareAmount => investmentAmount;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      unitId: json['unit_id'] as String? ?? '', 
      // Handle both investment_amount (schema) and share_amount (legacy)
      investmentAmount: (json['investment_amount'] as num?)?.toDouble() ?? (json['share_amount'] as num?)?.toDouble() ?? 0.0,
      // Map paid_amount or default to down_payment
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? (json['down_payment'] as num?)?.toDouble() ?? 0.0,
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
      projectName: json['projects'] != null ? json['projects']['name'] as String? : null,
      project: json['projects'] != null ? ProjectModel.fromJson(json['projects']) : null,
      unit: json['units'] != null ? UnitModel.fromJson(json['units']) : null,
      downPayment: (json['down_payment'] as num?)?.toDouble(),
      installmentsCount: json['installments_count'] as int? ?? 0,
      installmentsPaid: json['installments_paid'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'project_id': projectId,
      'unit_id': unitId,
      'investment_amount': investmentAmount,
      'paid_amount': paidAmount,
      'status': status.toJson(),
      'joined_at': joinedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'contract_id': contractId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'down_payment': downPayment,
      'installments_count': installmentsCount,
      'installments_paid': installmentsPaid,
      // We generally don't serialize project/unit back to DB here as they are relations
    };
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? unitId,
    double? investmentAmount,
    double? paidAmount,
    SubscriptionStatus? status,
    DateTime? joinedAt,
    DateTime? completedAt,
    String? contractId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? projectName,
    ProjectModel? project,
    UnitModel? unit,
    double? downPayment,
    int? installmentsCount,
    int? installmentsPaid,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      unitId: unitId ?? this.unitId,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      completedAt: completedAt ?? this.completedAt,
      contractId: contractId ?? this.contractId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      projectName: projectName ?? this.projectName,
      project: project ?? this.project,
      unit: unit ?? this.unit,
      downPayment: downPayment ?? this.downPayment,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      installmentsPaid: installmentsPaid ?? this.installmentsPaid,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        projectId,
        unitId,
        investmentAmount,
        paidAmount,
        status,
        joinedAt,
        completedAt,
        contractId,
        createdAt,
        updatedAt,
        projectName,
        project,
        unit,
        downPayment,
        installmentsCount,
        installmentsPaid,
      ];
}
