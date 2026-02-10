import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final double reservedBalance;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalPayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.reservedBalance = 0.0,
    this.totalDeposits = 0.0,
    this.totalWithdrawals = 0.0,
    this.totalPayments = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get availableBalance => balance - reservedBalance;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      reservedBalance: (json['reserved_balance'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (json['total_deposits'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (json['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      totalPayments: (json['total_payments'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'reserved_balance': reservedBalance,
      'total_deposits': totalDeposits,
      'total_withdrawals': totalWithdrawals,
      'total_payments': totalPayments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    double? reservedBalance,
    double? totalDeposits,
    double? totalWithdrawals,
    double? totalPayments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      reservedBalance: reservedBalance ?? this.reservedBalance,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      totalPayments: totalPayments ?? this.totalPayments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        balance,
        reservedBalance,
        totalDeposits,
        totalWithdrawals,
        totalPayments,
        createdAt,
        updatedAt,
      ];
}
