import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/wallet_card.dart';
import 'package:mmm/presentation/widgets/custom/transaction_item.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';
import 'package:mmm/presentation/widgets/common/error_widget.dart' as error_widgets;
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<WalletCubit>().loadWallet(authState.user.id);
      context.read<WalletCubit>().subscribeToWallet(authState.user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<WalletCubit>().unsubscribeFromWallet();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    switch (_tabController.index) {
      case 0:
        return transactions; // All
      case 1:
        return transactions
            .where((t) => t.type == TransactionType.deposit)
            .toList();
      case 2:
        return transactions
            .where((t) => t.type == TransactionType.withdrawal)
            .toList();
      case 3:
        return transactions
            .where((t) => t.type == TransactionType.payment)
            .toList();
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المحفظة'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is WalletTransactionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت العملية بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WalletLoading) {
            return _buildLoadingState();
          }

          if (state is WalletLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<WalletCubit>().refreshWallet(authState.user.id);
                }
              },
              child: CustomScrollView(
                slivers: [
                  // Wallet Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.spaceXXL),
                      child: WalletCard(
                        wallet: state.wallet,
                        onAddFunds: () {
                          Navigator.pushNamed(context, RouteNames.addFunds);
                        },
                        onWithdraw: () {
                          Navigator.pushNamed(context, RouteNames.withdrawFunds);
                        },
                      ),
                    ),
                  ),

                  // Stats Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceXXL,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'إجمالي الإيداعات',
                              amount: state.wallet.totalDeposits ?? 0,
                              icon: Icons.add_circle_outline,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceL),
                          Expanded(
                            child: _buildStatCard(
                              title: 'إجمالي السحب',
                              amount: state.wallet.totalWithdrawals ?? 0,
                              icon: Icons.remove_circle_outline,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Dimensions.spaceXXL),
                  ),

                  // Transactions Header & Tabs
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceXXL,
                          ),
                          child: Text(
                            'المعاملات',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        Container(
                          color: AppColors.white,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.primary,
                            isScrollable: true,
                            onTap: (_) => setState(() {}),
                            tabs: const [
                              Tab(text: 'الكل'),
                              Tab(text: 'إيداعات'),
                              Tab(text: 'سحوبات'),
                              Tab(text: 'مدفوعات'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List
                  Builder(
                    builder: (context) {
                      final filteredTransactions = _filterTransactions(state.transactions);
                      
                      if (filteredTransactions.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 80,
                                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: Dimensions.spaceL),
                                const Text(
                                  'لا توجد معاملات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.all(Dimensions.spaceXXL),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Dimensions.spaceL,
                                ),
                                child: TransactionItem(
                                  transaction: filteredTransactions[index],
                                  onTap: () => _showTransactionDetail(
                                    filteredTransactions[index],
                                  ),
                                ),
                              );
                            },
                            childCount: filteredTransactions.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      children: const [
        SkeletonList(itemCount: 5),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: Dimensions.spaceM),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: Dimensions.spaceXS),
          Text(
            '${amount.toStringAsFixed(0)} ر.س',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetail(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusXL),
            ),
          ),
          padding: const EdgeInsets.all(Dimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spaceXL),
              
              Text(
                'تفاصيل المعاملة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: Dimensions.spaceXL),
              
              _buildDetailRow('رقم المعاملة', transaction.id),
              _buildDetailRow('المبلغ', '${transaction.amount} ر.س'),
              _buildDetailRow('النوع', _getTypeText(transaction.type)),
              _buildDetailRow('الحالة', _getStatusText(transaction.status)),
              if (transaction.description != null)
                _buildDetailRow('الوصف', transaction.description!),
              _buildDetailRow('التاريخ', _formatDate(transaction.createdAt)),
              
              const SizedBox(height: Dimensions.spaceXXL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'إيداع';
      case TransactionType.withdrawal:
        return 'سحب';
      case TransactionType.payment:
        return 'دفعة';
      case TransactionType.refund:
        return 'استرداد';
      case TransactionType.commission:
        return 'عمولة';
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'قيد الانتظار';
      case TransactionStatus.processing:
        return 'جاري المعالجة';
      case TransactionStatus.completed:
        return 'مكتملة';
      case TransactionStatus.failed:
        return 'فشلت';
      case TransactionStatus.cancelled:
        return 'ملغية';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
