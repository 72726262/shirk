// lib/presentation/screens/subscriptions/subscriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/data/models/subscription_model.dart';

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
      appBar: AppBar(
        title: const Text('اشتراكاتي'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? const Center(child: Text('لا توجد اشتراكات'))
              : RefreshIndicator(
                  onRefresh: _loadSubscriptions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    itemCount: _subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = _subscriptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                        child: ListTile(
                          title: Text('مبلغ الاستثمار: ${sub.investmentAmount} ر.س'),
                          subtitle: Text('الحالة: ${sub.status}'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Navigate to detail screen
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
