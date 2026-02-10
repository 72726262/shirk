import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<WalletCubit>().loadTransactions(userId: authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل المعاملات'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            color: AppColors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Deposits', 'Withdrawals', 'Payments'].map((
                  type,
                ) {
                  final isSelected = _filterType == type;
                  return Padding(
                    padding: const EdgeInsets.only(left: Dimensions.spaceM),
                    child: ChoiceChip(
                      label: Text(_getTypeLabel(type)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _filterType = type);
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

          // Transactions List
          Expanded(
            child: BlocBuilder<WalletCubit, WalletState>(
              builder: (context, state) {
                if (state is WalletLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is WalletLoaded) {
                  var transactions = state.transactions;

                  if (_filterType != 'All') {
                    transactions = transactions
                        .where(
                          (t) =>
                              t.type.toLowerCase() == _filterType.toLowerCase(),
                        )
                        .toList();
                  }

                  if (transactions.isEmpty) {
                    return const Center(child: Text('لا توجد معاملات'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is Authenticated) {
                        await context.read<WalletCubit>().refreshTransactions(
                          authState.user.id,
                        );
                      }
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.spaceL),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final isCredit =
                            transaction.type.toLowerCase() == 'deposit';

                        return Card(
                          margin: const EdgeInsets.only(
                            bottom: Dimensions.spaceM,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (isCredit
                                          ? AppColors.success
                                          : AppColors.error)
                                      .withOpacity(0.1),
                              child: Icon(
                                isCredit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isCredit
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            title: Text(transaction.description.toString()),
                            subtitle: Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(transaction.createdAt),
                            ),
                            trailing: Text(
                              '${isCredit ? '+' : '-'}${currency.format(transaction.amount)}',
                              style: TextStyle(
                                color: isCredit
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'All':
        return 'الكل';
      case 'Deposits':
        return 'إيداعات';
      case 'Withdrawals':
        return 'سحوبات';
      case 'Payments':
        return 'مدفوعات';
      default:
        return type;
    }
  }
}
