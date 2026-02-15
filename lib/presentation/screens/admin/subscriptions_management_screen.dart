import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/presentation/cubits/admin/subscriptions_management_cubit.dart';

import 'package:intl/intl.dart';

class SubscriptionsManagementScreen extends StatelessWidget {
  const SubscriptionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SubscriptionsManagementCubit>();

    return Scaffold(
      body:
          BlocBuilder<
            SubscriptionsManagementCubit,
            SubscriptionsManagementState
          >(
            builder: (context, state) {
              if (state is SubscriptionsManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SubscriptionsManagementError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => cubit.loadSubscriptions(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (state is SubscriptionsManagementLoaded) {
                return Column(
                  children: [
                    // Tabs
                    _buildTabs(context, state, cubit),
                    // List
                    Expanded(
                      child: state.filteredSubscriptions.isEmpty
                          ? const Center(child: Text('لا توجد اشتراكات'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(Dimensions.spaceM),
                              itemCount: state.filteredSubscriptions.length,
                              itemBuilder: (context, index) {
                                final subscription =
                                    state.filteredSubscriptions[index];
                                return _buildSubscriptionCard(
                                  context,
                                  subscription,
                                  cubit,
                                );
                              },
                            ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
    );
  }

  Widget _buildTabs(
    BuildContext context,
    SubscriptionsManagementLoaded state,
    SubscriptionsManagementCubit cubit,
  ) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(context, 'الكل', 'all', state.filterStatus, cubit),
            _buildTab(
              context,
              'قيد الانتظار',
              'pending',
              state.filterStatus,
              cubit,
              badge: state.pendingCount,
            ),
            _buildTab(context, 'نشط', 'active', state.filterStatus, cubit),
            _buildTab(context, 'مكتمل', 'completed', state.filterStatus, cubit),
            _buildTab(context, 'ملغي', 'cancelled', state.filterStatus, cubit),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    String value,
    String currentValue,
    SubscriptionsManagementCubit cubit, {
    int? badge,
  }) {
    final isSelected = value == currentValue;

    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.spaceS),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => cubit.changeFilter(value),
            backgroundColor: Colors.grey[200],
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (badge != null && badge > 0)
            Positioned(
              top: -8,
              left: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  badge.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionModel subscription,
    SubscriptionsManagementCubit cubit,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: 'ر.س ');

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اشتراك #${subscription.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.projectName ?? 'مشروع غير معروف',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(subscription.status),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ: ${currencyFormat.format(subscription.investmentAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subscription.joinedAt != null
                      ? DateFormat('yyyy/MM/dd').format(subscription.joinedAt!)
                      : '-',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (subscription.status == SubscriptionStatus.pending) ...[
              const SizedBox(height: Dimensions.spaceM),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showApproveDialog(context, subscription.id, cubit),
                      icon: const Icon(Icons.check),
                      label: const Text('موافقة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showRejectDialog(context, subscription.id, cubit),
                      icon: const Icon(Icons.close),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SubscriptionStatus status) {
    Color color;
    String text;

    switch (status) {
      case SubscriptionStatus.pending:
        color = Colors.orange;
        text = 'قيد الانتظار';
        break;
      case SubscriptionStatus.active:
        color = Colors.green;
        text = 'نشط';
        break;
      case SubscriptionStatus.completed:
        color = Colors.blue;
        text = 'مكتمل';
        break;
      case SubscriptionStatus.cancelled:
        color = Colors.red;
        text = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    String subscriptionId,
    SubscriptionsManagementCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: const Text('هل أنت متأكد من الموافقة على هذا الاشتراك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.approveSubscription(subscriptionId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت الموافقة على الاشتراك')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    String subscriptionId,
    SubscriptionsManagementCubit cubit,
  ) {
    String? reason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هل أنت متأكد من رفض هذا الاشتراك؟'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'سبب الرفض (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => reason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              cubit.rejectSubscription(subscriptionId, reason);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم رفض الاشتراك')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
