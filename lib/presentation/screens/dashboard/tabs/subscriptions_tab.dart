import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/services/subscription_service.dart';
import 'package:intl/intl.dart';

class SubscriptionsTab extends StatefulWidget {
  final String userId;

  const SubscriptionsTab({super.key, required this.userId});

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subscriptions = await _subscriptionService.getUserSubscriptions(
        widget.userId,
      );
      setState(() {
        _subscriptions = subscriptions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اشتراكاتي'),
        backgroundColor: AppColors.primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Dimensions.spaceM),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: _loadSubscriptions,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: Dimensions.spaceM),
            const Text('لا توجد اشتراكات حالياً'),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('تصفح المشاريع'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: Dimensions.screenPadding,
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          return _buildSubscriptionCard(_subscriptions[index]);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionModel subscription) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSubscriptionDetails(subscription),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'المشروع ${subscription.projectId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(subscription.status),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),

              // Investment Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.attach_money,
                      label: 'قيمة الاستثمار',
                      value:
                          '${subscription.shareAmount.toStringAsFixed(0)} ر.س',
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.payments,
                      label: 'المدفوع',
                      value:
                          '${subscription.paidAmount.toStringAsFixed(0)} ر.س',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('نسبة السداد', style: TextStyle(fontSize: 12)),
                      Text(
                        '${subscription.paidPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    child: LinearProgressIndicator(
                      value: subscription.paidPercentage / 100,
                      backgroundColor: AppColors.gray200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (subscription.joinedAt != null)
                    Text(
                      'تاريخ الانضمام: ${DateFormat('dd/MM/yyyy').format(subscription.joinedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _showSubscriptionDetails(subscription),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('التفاصيل'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(SubscriptionStatus status) {
    Color color;
    switch (status) {
      case SubscriptionStatus.pending:
        color = AppColors.warning;
        break;
      case SubscriptionStatus.active:
        color = AppColors.success;
        break;
      case SubscriptionStatus.completed:
        color = AppColors.info;
        break;
      case SubscriptionStatus.cancelled:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showSubscriptionDetails(SubscriptionModel subscription) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusXL),
            ),
          ),
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: FutureBuilder<List<InstallmentModel>>(
            future: _subscriptionService.getInstallments(subscription.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }

              final installments = snapshot.data ?? [];

              return ListView(
                controller: scrollController,
                children: [
                  // Header
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
                  const SizedBox(height: Dimensions.spaceL),
                  const Text(
                    'تفاصيل الاشتراك',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Subscription Summary
                  _buildDetailItem(
                    'قيمة الاستثمار',
                    '${subscription.shareAmount.toStringAsFixed(0)} ر.س',
                  ),
                  _buildDetailItem(
                    'المبلغ المدفوع',
                    '${subscription.paidAmount.toStringAsFixed(0)} ر.س',
                  ),
                  _buildDetailItem(
                    'المبلغ المتبقي',
                    '${subscription.remainingAmount.toStringAsFixed(0)} ر.س',
                  ),
                  const Divider(height: Dimensions.spaceXL),

                  // Installments
                  const Text(
                    'الأقساط',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  if (installments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(Dimensions.spaceL),
                        child: Text('لا توجد أقساط'),
                      ),
                    )
                  else
                    ...installments.map(
                      (installment) => _buildInstallmentCard(installment),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInstallmentCard(InstallmentModel installment) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceS),
      child: ListTile(
        leading: Icon(
          installment.isPaid ? Icons.check_circle : Icons.schedule,
          color: installment.isPaid
              ? AppColors.success
              : installment.isOverdue
              ? AppColors.error
              : AppColors.warning,
        ),
        title: Text('قسط ${installment.installmentNumber}'),
        subtitle: Text(
          'تاريخ الاستحقاق: ${DateFormat('dd/MM/yyyy').format(installment.dueDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ' ${installment.amount.toStringAsFixed(0)} ر.س',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              installment.status.name,
              style: TextStyle(
                fontSize: 11,
                color: installment.isPaid
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
