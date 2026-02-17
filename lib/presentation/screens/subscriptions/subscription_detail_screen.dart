import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/presentation/widgets/custom/standard_unit_card.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final String subscriptionId;
  final SubscriptionModel? subscription; // Optional initially

  const SubscriptionDetailScreen({
    super.key,
    required this.subscriptionId,
    this.subscription,
  });

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  final _repository = SubscriptionRepository();
  late Future<SubscriptionModel> _subscriptionFuture;
  late Future<List<InstallmentModel>> _installmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.subscription != null) {
      _subscriptionFuture = Future.value(widget.subscription);
    } else {
      _subscriptionFuture = _repository.getSubscriptionById(
        widget.subscriptionId,
      );
    }
    _installmentsFuture = _repository.getInstallments(widget.subscriptionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تفاصيل الاستثمار')),
      body: FutureBuilder<SubscriptionModel>(
        future: _subscriptionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('لم يتم العثور على الاستثمار'));
          }

          final subscription = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unit & Project Card
                if (subscription.unit != null && subscription.project != null)
                  StandardUnitCard(
                    unit: subscription.unit!,
                    project: subscription.project!,
                  ),

                const SizedBox(height: Dimensions.spaceL),

                // 2. Financial Summary
                _buildFinancialSummary(subscription),

                const SizedBox(height: Dimensions.spaceL),

                // 3. Installments Section
                _buildInstallmentsSection(),

                const SizedBox(height: Dimensions.spaceL),

                // 4. Construction Updates Link
                if (subscription.project != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.constructionTracking,
                          arguments: subscription.project!.id,
                        );
                      },
                      icon: const Icon(Icons.construction),
                      label: const Text('متابعة حالة البناء'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(Dimensions.spaceM),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary(SubscriptionModel subscription) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'ر.س',
      decimalDigits: 0,
    );
    final paidAmount =
        subscription.investmentAmount - subscription.remainingAmount;
    final progress = subscription.investmentAmount > 0
        ? paidAmount / subscription.investmentAmount
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الملخص المالي',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceM),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.gray200,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: Dimensions.spaceS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% مدفوع',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currencyFormat.format(subscription.remainingAmount)} متبقى',
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ),

          const Divider(height: Dimensions.spaceXL),

          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'إجمالي الاستثمار',
                  currencyFormat.format(subscription.investmentAmount),
                  Icons.monetization_on,
                  AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'المدفوع',
                  currencyFormat.format(paidAmount),
                  Icons.check_circle_outline,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
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

  Widget _buildInstallmentsSection() {
    return FutureBuilder<List<InstallmentModel>>(
      future: _installmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final installments = snapshot.data ?? [];
        if (installments.isEmpty) return const SizedBox.shrink();

        // Get next pending installment
        final nextInstallment = installments.firstWhere(
          (i) =>
              i.status == InstallmentStatus.pending ||
              i.status == InstallmentStatus.overdue,
          orElse: () => installments.last,
        ); // Just a fallback, won't be used if all paid

        final hasPending = installments.any(
          (i) =>
              i.status == InstallmentStatus.pending ||
              i.status == InstallmentStatus.overdue,
        );

        return Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأقساط',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        RouteNames.installments,
                        arguments: widget.subscriptionId,
                      );
                    },
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),

              if (hasPending) ...[
                const SizedBox(height: Dimensions.spaceM),
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'القسط القادم',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            DateFormat(
                              'yyyy-MM-dd',
                            ).format(nextInstallment.dueDate),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${nextInstallment.amount} ر.س',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                RouteNames.payment,
                                arguments: {
                                  'subscriptionId': widget.subscriptionId,
                                  'amount': nextInstallment.amount,
                                  'installmentId': nextInstallment.id,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('دفع الآن'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: Dimensions.spaceM),
                const Center(
                  child: Text(
                    'جميع الأقساط مدفوعة 🎉',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
