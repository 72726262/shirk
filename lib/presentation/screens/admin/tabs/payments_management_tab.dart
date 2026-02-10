import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/payments_management_cubit.dart';
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
            child: BlocBuilder<PaymentsManagementCubit, PaymentsManagementState>(
              builder: (context, state) {
                if (state is PaymentsLoading) {
                  return const SkeletonList();
                }
                if (state is PaymentsLoaded) {
                  if (state.transactions.isEmpty) {
                    return const Center(child: Text('لا توجد مدفوعات'));
                  }
                  return _buildTransactionsTable(state.transactions);
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
              context.read<PaymentsManagementCubit>().loadTransactions(status: 'completed');
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
              context.read<PaymentsManagementCubit>().loadTransactions(status: 'pending');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTable(List<Map<String, dynamic>> transactions) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withOpacity(0.05),
          ),
          columns: const [
            DataColumn(label: Text('المعرف')),
            DataColumn(label: Text('العميل')),
            DataColumn(label: Text('المشروع')),
            DataColumn(label: Text('المبلغ')),
            DataColumn(label: Text('التاريخ')),
            DataColumn(label: Text('الحالة')),
          ],
          rows: transactions.map((t) {
            final profile = t['profiles'] ?? {};
            final project = t['projects'] ?? {};
            return DataRow(
              cells: [
                DataCell(Text((t['id'] as String).substring(0, 8))),
                DataCell(Text(profile['full_name'] ?? '-')),
                DataCell(Text(project['name_ar'] ?? '-')),
                DataCell(Text('${t['amount']} ر.س')),
                DataCell(Text(DateFormat('yyyy-MM-dd').format(DateTime.parse(t['created_at'])))),
                DataCell(_buildStatusChip(t['status'])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = AppColors.success;
        label = 'مكتمل';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'معلق';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'فشل';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
