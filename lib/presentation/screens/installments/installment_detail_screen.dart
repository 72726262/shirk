// lib/presentation/screens/installments/installment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart';

class InstallmentDetailScreen extends StatelessWidget {
  final InstallmentModel installment;

  const InstallmentDetailScreen({super.key, required this.installment});

  @override
  Widget build(BuildContext context) {
    final isOverdue = installment.status == InstallmentStatus.pending &&
        installment.dueDate.isBefore(DateTime.now());
    final totalAmount = installment.amount + installment.lateFeeAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('قسط رقم ${installment.installmentNumber}'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        children: [
          // Status Card
          _buildStatusCard(isOverdue),
          
          const SizedBox(height: Dimensions.spaceL),

          // Amount Details
          _buildDetailsCard(
            'تفاصيل المبلغ',
            [
              _buildDetailRow('المبلغ الأساسي', '${installment.amount.toStringAsFixed(2)} ر.س'),
              if (installment.lateFeeApplied && installment.lateFeeAmount > 0)
                _buildDetailRow(
                  'غرامة التأخير',
                  '${installment.lateFeeAmount.toStringAsFixed(2)} ر.س',
                  valueColor: AppColors.error,
                ),
              const Divider(),
              _buildDetailRow(
                'الإجمالي',
                '${totalAmount.toStringAsFixed(2)} ر.س',
                isTotal: true,
              ),
            ],
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Dates Card
          _buildDetailsCard(
            'التواريخ',
            [
              _buildDetailRow(
                'تاريخ الاستحقاق',
                DateFormat('yyyy-MM-dd').format(installment.dueDate),
              ),
              if (installment.paidAt != null)
                _buildDetailRow(
                  'تاريخ الدفع',
                  DateFormat('yyyy-MM-dd HH:mm').format(installment.paidAt!),
                ),
              _buildDetailRow(
                'تاريخ الإنشاء',
                DateFormat('yyyy-MM-dd').format(installment.createdAt),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Payment Transaction Info
          if (installment.paymentTransactionId != null)
            _buildDetailsCard(
              'معلومات الدفع',
              [
                _buildDetailRow(
                  'رقم المعاملة',
                  installment.paymentTransactionId!,
                ),
              ],
            ),

          const SizedBox(height: Dimensions.space3XL),

          // Pay Button
          if (installment.status == InstallmentStatus.pending)
            PrimaryButton.withIcon(
              text: 'دفع القسط',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.payment,
                  arguments: {
                    'subscriptionId': installment.subscriptionId,
                    'amount': totalAmount,
                    'installmentId': installment.id,
                  },
                );
              },
              icon: Icons.payment,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isOverdue) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String description;

    if (installment.isPaid) {
      statusColor = AppColors.success;
      statusText = 'تم الدفع';
      statusIcon = Icons.check_circle;
      description = 'تم دفع هذا القسط بنجاح';
    } else if (isOverdue) {
      statusColor = AppColors.error;
      statusText = 'متأخر';
      statusIcon = Icons.warning;
      description = 'هذا القسط متأخر عن موعد الاستحقاق';
    } else {
      statusColor = AppColors.warning;
      statusText = 'معلق';
      statusIcon = Icons.schedule;
      description = 'في انتظار الدفع';
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: Dimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: statusColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Dimensions.spaceL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isTotal ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
