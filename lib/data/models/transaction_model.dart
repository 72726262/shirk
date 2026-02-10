import 'package:equatable/equatable.dart';

enum TransactionType {
  deposit,
  withdrawal,
  payment,
  refund,
  commission;

  String toJson() => name;
  
  static TransactionType fromJson(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.deposit,
    );
  }

  String toLowerCase() => name.toLowerCase();
}

enum TransactionStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled;

  String toJson() => name;
  
  static TransactionStatus fromJson(String value) {
    return TransactionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionStatus.pending,
    );
  }
}

enum PaymentMethod {
  wallet,
  bankCard,
  bankTransfer,
  cash;

  String toJson() => name;
  
  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentMethod.wallet,
    );
  }
}

class TransactionModel extends Equatable {
  final String id;
  final String walletId;
  final String userId;
  final TransactionType type;
  final double amount;
  final TransactionStatus status;
  final PaymentMethod? paymentMethod;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    this.status = TransactionStatus.pending,
    this.paymentMethod,
    this.referenceId,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      userId: json['user_id'] as String,
      type: TransactionType.fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] != null
          ? TransactionStatus.fromJson(json['status'] as String)
          : TransactionStatus.pending,
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromJson(json['payment_method'] as String)
          : null,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'user_id': userId,
      'type': type.toJson(),
      'amount': amount,
      'status': status.toJson(),
      'payment_method': paymentMethod?.toJson(),
      'reference_id': referenceId,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Computed properties for backwards compatibility
  String get clientName => metadata?['client_name'] as String? ?? 'عميل';
  String get clientNa => clientName; // Legacy alias

  TransactionModel copyWith({
    String? id,
    String? walletId,
    String? userId,
    TransactionType? type,
    double? amount,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        userId,
        type,
        amount,
        status,
        paymentMethod,
        referenceId,
        description,
        metadata,
        createdAt,
        updatedAt,
      ];
}
