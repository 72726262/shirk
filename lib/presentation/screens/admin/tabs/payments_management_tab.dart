import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/payments_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/screens/payment_detail_screen.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';
import 'package:intl/intl.dart';

class PaymentsManagementTab extends StatefulWidget {
  const PaymentsManagementTab({super.key});

  @override
  State<PaymentsManagementTab> createState() => _PaymentsManagementTabState();
}

class _PaymentsManagementTabState extends State<PaymentsManagementTab> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<PaymentsManagementCubit>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: Dimensions.spaceL),
          Expanded(
            child:
                BlocBuilder<PaymentsManagementCubit, PaymentsManagementState>(
              builder: (context, state) {
                if (state is PaymentsLoading) {
                  return const SkeletonList();
                }
                if (state is PaymentsLoaded) {
                  if (state.transactions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment,
                              size: 64, color: AppColors.gray400),
                          SizedBox(height: Dimensions.spaceL),
                          Text('لا توجد مدفوعات'),
                        ],
                      ),
                    );
                  }
                  return _buildPaymentsList(state.transactions);
                }
                if (state is PaymentsError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('الكل'),
            selected: _selectedStatus == null,
            onSelected: (_) {
              setState(() => _selectedStatus = null);
              context.read<PaymentsManagementCubit>().loadTransactions();
            },
          ),
          const SizedBox(width: Dimensions.spaceS),
          FilterChip(
            label: const Text('مكتمل'),
            selected: _selectedStatus == 'completed',
            backgroundColor: AppColors.success.withOpacity(0.1),
            selectedColor: AppColors.success.withOpacity(0.3),
            onSelected: (_) {
              setState(() => _selectedStatus = 'completed');
              context
                  .read<PaymentsManagementCubit>()
                  .loadTransactions(status: 'completed');
            },
          ),
          const SizedBox(width: Dimensions.spaceS),
          FilterChip(
            label: const Text('معلق'),
            selected: _selectedStatus == 'pending',
            backgroundColor: AppColors.warning.withOpacity(0.1),
            selectedColor: AppColors.warning.withOpacity(0.3),
            onSelected: (_) {
              setState(() => _selectedStatus = 'pending');
              context
                  .read<PaymentsManagementCubit>()
                  .loadTransactions(status: 'pending');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> transactions) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _PaymentCard(transaction: transaction);
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _PaymentCard({required this.transaction});

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'معلق';
      case 'failed':
        return 'فشل';
      default:
        return 'غير معروف';
    }
  }

  IconData _getPaymentIcon(String? type) {
    switch (type) {
      case 'subscription':
        return Icons.autorenew;
      case 'installment':
        return Icons.payments;
      case 'contract':
        return Icons.description;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String?;
    final type = transaction['type'] as String?;
    final createdAt = transaction['created_at'] as String?;
    final userName = transaction['user_name'] as String? ?? 'غير معروف';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailScreen(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  _getPaymentIcon(type),
                  color: _getStatusColor(status),
                  size: 28,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),

              // Payment Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$amount ر.س',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceS),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusS),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(width: Dimensions.spaceS),
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: Dimensions.spaceXS),
                          Text(
                            DateFormat('yyyy-MM-dd').format(
                              DateTime.parse(createdAt),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
