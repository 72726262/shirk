import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';
import 'package:intl/intl.dart';

class ManagePaymentsScreen extends StatefulWidget {
  const ManagePaymentsScreen({super.key});

  @override
  State<ManagePaymentsScreen> createState() => _ManagePaymentsScreenState();
}

class _ManagePaymentsScreenState extends State<ManagePaymentsScreen> {
  String _filter = 'pending';

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadPayments(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المدفوعات'),
        backgroundColor: AppColors.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: Row(
              children: ['pending', 'approved', 'rejected'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(left: Dimensions.spaceM),
                  child: ChoiceChip(
                    label: Text(_getFilterLabel(filter)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _filter = filter);
                      context.read<AdminCubit>().loadPayments(filter);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentsLoaded) {
            final payments = state.payments;

            if (payments.isEmpty) {
              return const Center(child: Text('لا توجد مدفوعات'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<AdminCubit>().refreshPayments(_filter);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.spaceL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                payment.clientNa,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                currency.format(payment.amount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          Text(
                            payment.description?.toString() ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(payment.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          if (_filter == 'pending') ...[
                            const SizedBox(height: Dimensions.spaceL),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectPayment(payment.id),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.error,
                                      ),
                                    ),
                                    child: const Text(
                                      'رفض',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Dimensions.spaceM),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approvePayment(payment.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                    child: const Text('موافقة'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'pending':
        return 'معلقة';
      case 'approved':
        return 'مقبولة';
      case 'rejected':
        return 'مرفوضة';
      default:
        return filter;
    }
  }

  Future<void> _approvePayment(String paymentId) async {
    await context.read<AdminCubit>().approvePayment(paymentId);
  }

  Future<void> _rejectPayment(String paymentId) async {
    await context.read<AdminCubit>().rejectPayment(paymentId);
  }
}
