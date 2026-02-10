// lib/presentation/screens/installments/installments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/repositories/installment_repository.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/installments/installments_cubit.dart';
import 'package:mmm/presentation/screens/installments/installment_detail_screen.dart';
import 'package:intl/intl.dart';

class InstallmentsScreen extends StatelessWidget {
  final String? subscriptionId;

  const InstallmentsScreen({super.key, this.subscriptionId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = InstallmentsCubit(
          repository: InstallmentRepository(),
        );
        
        final authState = context.read<AuthCubit>().state;
        if (authState is Authenticated) {
          if (subscriptionId != null) {
            cubit.loadSubscriptionInstallments(subscriptionId!);
          } else {
            cubit.loadUserInstallments(authState.user.id);
          }
        }
        
        return cubit;
      },
      child: const _InstallmentsView(),
    );
  }
}

class _InstallmentsView extends StatelessWidget {
  const _InstallmentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأقساط'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                final cubit = context.read<InstallmentsCubit>();
                switch (value) {
                  case 'all':
                    cubit.loadUserInstallments(authState.user.id);
                    break;
                  case 'overdue':
                    cubit.loadOverdueInstallments(authState.user.id);
                    break;
                  case 'upcoming':
                    cubit.loadUpcomingInstallments(authState.user.id);
                    break;
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('جميع الأقساط')),
              const PopupMenuItem(value: 'overdue', child: Text('متأخرة')),
              const PopupMenuItem(value: 'upcoming', child: Text('قادمة')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<InstallmentsCubit, InstallmentsState>(
        builder: (context, state) {
          if (state is InstallmentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InstallmentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: Dimensions.spaceL),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (state is InstallmentsLoaded) {
            if (state.installments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text('لا توجد أقساط'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<InstallmentsCubit>()
                      .loadUserInstallments(authState.user.id);
                }
              },
              child: Column(
                children: [
                  _buildSummaryCards(state),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.spaceL),
                      itemCount: state.installments.length,
                      itemBuilder: (context, index) {
                        final installment = state.installments[index];
                        return _buildInstallmentCard(context, installment);
                      },
                    ),
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

  Widget _buildSummaryCards(InstallmentsLoaded state) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'المتأخرة',
              '${state.overdueCount}',
              Icons.warning,
              AppColors.error,
            ),
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: _buildSummaryCard(
              'القادمة',
              '${state.upcomingCount}',
              Icons.schedule,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: _buildSummaryCard(
              'الإجمالي',
              '${state.installments.length}',
              Icons.receipt,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: Dimensions.spaceXS),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentCard(BuildContext context, InstallmentModel installment) {
    final isOverdue = installment.status == InstallmentStatus.pending && 
        installment.dueDate.isBefore(DateTime.now());
    
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (installment.isPaid) {
      statusColor = AppColors.success;
      statusText = 'مدفوع';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = AppColors.error;
      statusText = 'متأخر';
      statusIcon = Icons.warning;
    } else {
      statusColor = AppColors.warning;
      statusText = 'معلق';
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstallmentDetailScreen(installment: installment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceS),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قسط رقم ${installment.installmentNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 13, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${installment.amount.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (installment.lateFeeApplied && installment.lateFeeAmount > 0)
                        Text(
                          '+ ${installment.lateFeeAmount.toStringAsFixed(2)} ر.س غرامة',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: Dimensions.spaceL * 2),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: Dimensions.spaceS),
                  Text(
                    'تاريخ الاستحقاق: ${DateFormat('yyyy-MM-dd').format(installment.dueDate)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (installment.paidAt != null) ...[
                const SizedBox(height: Dimensions.spaceS),
                Row(
                  children: [
                    Icon(Icons.check, size: 16, color: AppColors.success),
                    const SizedBox(width: Dimensions.spaceS),
                    Text(
                      'تم الدفع: ${DateFormat('yyyy-MM-dd').format(installment.paidAt!)}',
                      style: TextStyle(fontSize: 13, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
