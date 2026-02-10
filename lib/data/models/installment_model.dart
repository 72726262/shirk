import 'package:equatable/equatable.dart';

enum InstallmentStatus {
  pending,
  paid,
  overdue,
  waived,
  cancelled,
}

class InstallmentModel extends Equatable {
  final String id;
  final String subscriptionId;
  final String userId;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String? paymentTransactionId;
  final double lateFeeAmount;
  final bool lateFeeApplied;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentModel({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    this.paymentTransactionId,
    this.lateFeeAmount = 0.0,
    this.lateFeeApplied = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    return InstallmentModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      userId: json['user_id'] as String,
      installmentNumber: json['installment_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: InstallmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InstallmentStatus.pending,
      ),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      paymentTransactionId: json['payment_transaction_id'] as String?,
      lateFeeAmount: json['late_fee_amount'] != null
          ? (json['late_fee_amount'] as num).toDouble()
          : 0.0,
      lateFeeApplied: json['late_fee_applied'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'user_id': userId,
      'installment_number': installmentNumber,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'status': status.name,
      'paid_at': paidAt?.toIso8601String(),
      'payment_transaction_id': paymentTransactionId,
      'late_fee_amount': lateFeeAmount,
      'late_fee_applied': lateFeeApplied,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPaid => status == InstallmentStatus.paid;
  bool get isOverdue => status == InstallmentStatus.overdue;
  bool get isPending => status == InstallmentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        userId,
        installmentNumber,
        amount,
        dueDate,
        status,
        paidAt,
        paymentTransactionId,
        lateFeeAmount,
        lateFeeApplied,
        createdAt,
        updatedAt,
      ];
}
