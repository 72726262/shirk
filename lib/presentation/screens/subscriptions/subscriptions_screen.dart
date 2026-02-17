import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/routes/route_names.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _repository = SubscriptionRepository();
  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      try {
        final subs = await _repository.getSubscriptionsByUser(authState.user.id);
        setState(() {
          _subscriptions = subs;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تحميل الاشتراكات: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('استثماراتي'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      return _buildSubscriptionCard(_subscriptions[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monetization_on_outlined, size: 80, color: AppColors.gray300),
          const SizedBox(height: Dimensions.spaceL),
          const Text(
            'لا توجد استثمارات نشطة',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: Dimensions.spaceM),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.projectsList);
            },
            child: const Text('تصفح المشاريع'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(SubscriptionModel subscription) {
    final unit = subscription.unit;
    final project = subscription.project;
    final isPaid = subscription.status == SubscriptionStatus.active; // Or fully paid logic

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusL)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.subscriptionDetail,
            arguments: subscription,
          );
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Project Name & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project?.name ?? 'مشروع غير معروف',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(subscription.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Text(
                      _getStatusText(subscription.status),
                      style: TextStyle(
                        color: _getStatusColor(subscription.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),
              
              // Unit Info
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      image: project?.imageUrl != null
                          ? DecorationImage(image: NetworkImage(project!.imageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: project?.imageUrl == null
                        ? const Icon(Icons.apartment, color: AppColors.gray400)
                        : null,
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وحدة #${unit?.unitNumber ?? '?'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${unit?.areaSqm ?? 0} م² • ${unit?.bedrooms ?? 0} غرف',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray400),
                ],
              ),
              
              const Divider(height: Dimensions.spaceL),
              
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المدفوع', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${(subscription.investmentAmount - subscription.remainingAmount).toStringAsFixed(0)} ر.س',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('المتبقي', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${subscription.remainingAmount.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.pending:
        return AppColors.warning;
      case SubscriptionStatus.cancelled:
        return AppColors.error;
      case SubscriptionStatus.completed:
        return AppColors.primary;
    }
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'نشط';
      case SubscriptionStatus.pending:
        return 'قيد الانتظار';
      case SubscriptionStatus.cancelled:
        return 'ملغي';
      case SubscriptionStatus.completed:
        return 'مكتمل';
    }
  }
}
