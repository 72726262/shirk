import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy - hh:mm a', 'ar');

    final isPositive = transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.refund;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1),
            borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type
                    Text(
                      _getTypeLabel(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),

                    // Description or Reference
                    if (transaction.description != null)
                      Text(
                        transaction.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (transaction.referenceId != null)
                      Text(
                        'مرجع: ${transaction.referenceId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    const SizedBox(height: Dimensions.spaceXS),

                    // Date & Status
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Text(
                          dateFormatter.format(transaction.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                        ),
                        const SizedBox(width: Dimensions.spaceM),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusS),
                          ),
                          child: Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'} ${currencyFormatter.format(transaction.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.success : AppColors.error,
                        ),
                  ),
                  if (transaction.paymentMethod != null) ...[
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      _getPaymentMethodLabel(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (transaction.type) {
      case TransactionType.deposit:
        return 'إيداع';
      case TransactionType.withdrawal:
        return 'سحب';
      case TransactionType.payment:
        return 'دفع';
      case TransactionType.refund:
        return 'استرداد';
      case TransactionType.commission:
        return 'عمولة';
    }
  }

  String _getStatusLabel() {
    switch (transaction.status) {
      case TransactionStatus.pending:
        return 'قيد الانتظار';
      case TransactionStatus.processing:
        return 'جاري المعالجة';
      case TransactionStatus.completed:
        return 'مكتمل';
      case TransactionStatus.failed:
        return 'فشل';
      case TransactionStatus.cancelled:
        return 'ملغي';
    }
  }

  String _getPaymentMethodLabel() {
    switch (transaction.paymentMethod!) {
      case PaymentMethod.wallet:
        return 'محفظة';
      case PaymentMethod.bankCard:
        return 'بطاقة';
      case PaymentMethod.bankTransfer:
        return 'تحويل';
      case PaymentMethod.cash:
        return 'نقدي';
    }
  }

  Color _getTypeColor() {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.refund:
        return AppColors.success;
      case TransactionType.withdrawal:
      case TransactionType.payment:
        return AppColors.error;
      case TransactionType.commission:
        return AppColors.warning;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
      case TransactionStatus.processing:
        return AppColors.warning;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getTypeIcon() {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Icons.add_circle_outline;
      case TransactionType.withdrawal:
        return Icons.remove_circle_outline;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.replay_circle_filled_outlined;
      case TransactionType.commission:
        return Icons.percent;
    }
  }
}
