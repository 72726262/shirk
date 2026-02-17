import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/presentation/cubits/projects/payments_cubit.dart';
import 'package:intl/intl.dart';

class TransactionsTab extends StatefulWidget {
  final String userId;

  const TransactionsTab({super.key, required this.userId});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  // We use InstallmentModel because that's what PaymentsRepository returns now
  // and it contains the joined data we need.
  InstallmentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Load all user transactions (installments)
    context.read<PaymentsCubit>().loadAllUserTransactions(widget.userId);
  }

  Future<void> _loadTransactions() async {
    await context.read<PaymentsCubit>().loadAllUserTransactions(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات المالية'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', null),
                  const SizedBox(width: Dimensions.spaceS),
                  ...InstallmentStatus.values.map(
                    (status) => Padding(
                      padding: const EdgeInsets.only(left: Dimensions.spaceS),
                      child: _buildFilterChip(_getStatusLabel(status), status),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Transactions List
          Expanded(
            child: BlocBuilder<PaymentsCubit, PaymentsState>(
              builder: (context, state) {
                if (state is PaymentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PaymentsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: Dimensions.spaceM),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: Dimensions.spaceM),
                        ElevatedButton(
                          onPressed: _loadTransactions,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is PaymentsLoaded) {
                  final transactions = state.payments.where((t) {
                    if (_filterStatus == null) return true;
                    return t.status == _filterStatus;
                  }).toList();

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          Text(
                            _filterStatus != null
                                ? 'لا توجد معاملات بحالة ${_getStatusLabel(_filterStatus!)}'
                                : 'لا توجد معاملات',
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      padding: Dimensions.screenPadding,
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(transactions[index]);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, InstallmentStatus? status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? status : null;
        });
      },
      backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTransactionCard(InstallmentModel transaction) {
    // Determine if it's a payment (negative/red for user perspective as they pay)
    // or refund/commission (positive/green).
    // For now, installments are payments FROM user.
    final isPayment = true;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                backgroundColor: _getStatusColor(transaction.status).withOpacity(0.1),
                child: Icon(
                  Icons.payment,
                  color: _getStatusColor(transaction.status),
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دفعة رقم ${transaction.installmentNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      DateFormat('dd/MM/yyyy').format(transaction.dueDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (transaction.paidAt != null) ...[
                      const SizedBox(height: Dimensions.spaceXS),
                      Text(
                        'تم الدفع: ${DateFormat('dd/MM/yyyy').format(transaction.paidAt!)}',
                         style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                    '${transaction.amount.toStringAsFixed(0)} ر.س',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isPayment ? AppColors.textPrimary : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXS),
                  _buildStatusChip(transaction.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(InstallmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusS),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTransactionDetails(InstallmentModel transaction) {
    // We expect the repository to have fetched related data
    // Ideally InstallmentModel should have fields for project/unit names or
    // we access them from the JSON if we mapped them to a specific field.
    // For now, let's assume we can display the basic info + metadata if available.
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _TransactionDetailSheet(
          transaction: transaction,
          scrollController: controller,
        ),
      ),
    );
  }

  String _getStatusLabel(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.pending:
        return 'مستحقة';
      case InstallmentStatus.paid:
        return 'مدفوعة';
      case InstallmentStatus.overdue:
        return 'متأخرة';
      case InstallmentStatus.waived:
        return 'معفاة';
      case InstallmentStatus.cancelled:
        return 'ملغاة';
    }
  }

  Color _getStatusColor(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.pending:
        return AppColors.warning;
      case InstallmentStatus.paid:
        return AppColors.success;
      case InstallmentStatus.overdue:
        return AppColors.error;
      case InstallmentStatus.waived:
        return AppColors.info;
      case InstallmentStatus.cancelled:
        return AppColors.textSecondary;
    }
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final InstallmentModel transaction;
  final ScrollController scrollController;

  const _TransactionDetailSheet({
    required this.transaction,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: ListView(
        controller: scrollController,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.spaceL),
          
          // Amount Header
          Center(
            child: Column(
              children: [
                Text(
                  'مبلغ المعاملة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceS),
                Text(
                  '${transaction.amount.toStringAsFixed(0)} ر.س',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: Dimensions.spaceXL),
          const Divider(),
          const SizedBox(height: Dimensions.spaceL),

          // Details List
          _buildDetailRow('رقم الدفعة', '#${transaction.installmentNumber}'),
          _buildDetailRow('الحالة', _getStatusLabel(transaction.status), 
              valueColor: _getStatusColor(transaction.status)),
          _buildDetailRow('تاريخ الاستحقاق', 
              DateFormat('dd/MM/yyyy').format(transaction.dueDate)),
          
          if (transaction.paidAt != null)
            _buildDetailRow('تاريخ الدفع', 
                DateFormat('dd/MM/yyyy hh:mm a').format(transaction.paidAt!)),

          if (transaction.paymentTransactionId != null)
             _buildDetailRow('رقم المرجع', transaction.paymentTransactionId!),
             
          if (transaction.projectName != null)
             _buildDetailRow('المشروع', transaction.projectName!),
             
          if (transaction.unitNumber != null)
             _buildDetailRow('الوحدة', '#${transaction.unitNumber}'),

        ],
      ),
    );
  }
  
  String _getStatusLabel(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.pending: return 'مستحقة';
      case InstallmentStatus.paid: return 'مدفوعة';
      case InstallmentStatus.overdue: return 'متأخرة';
      case InstallmentStatus.waived: return 'معفاة';
      case InstallmentStatus.cancelled: return 'ملغاة';
    }
  }
  
  Color _getStatusColor(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.pending: return AppColors.warning;
      case InstallmentStatus.paid: return AppColors.success;
      case InstallmentStatus.overdue: return AppColors.error;
      case InstallmentStatus.waived: return AppColors.info;
      case InstallmentStatus.cancelled: return AppColors.textSecondary;
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
