import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart';

enum PaymentMethod { wallet, creditCard, bankTransfer }

class PaymentScreen extends StatefulWidget {
  final String subscriptionId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.subscriptionId,
    required this.amount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.wallet;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الدفع'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<JoinFlowCubit, JoinFlowState>(
        listener: (context, state) {
          if (state is PaymentCompleted) {
            Navigator.pushNamed(
              context,
              RouteNames.eSignature,
              arguments: {'subscriptionId': widget.subscriptionId},
            );
          }
          if (state is JoinFlowError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isProcessing = state is JoinFlowLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Card
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceXXL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payment,
                        color: AppColors.white,
                        size: 48,
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      Text(
                        'المبلغ المطلوب',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Text(
                        currency.format(widget.amount),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Payment Methods
                Text(
                  'طريقة الدفع',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                _buildPaymentMethod(
                  method: PaymentMethod.wallet,
                  icon: Icons.account_balance_wallet,
                  title: 'المحفظة',
                  subtitle: 'الدفع من رصيد المحفظة',
                  badge: 'مستحسن',
                  badgeColor: AppColors.success,
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceM),

                _buildPaymentMethod(
                  method: PaymentMethod.creditCard,
                  icon: Icons.credit_card,
                  title: 'بطاقة ائتمان',
                  subtitle: 'Visa, Mastercard, Mada',
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceM),

                _buildPaymentMethod(
                  method: PaymentMethod.bankTransfer,
                  icon: Icons.account_balance,
                  title: 'تحويل بنكي',
                  subtitle: 'يستغرق 1-3 أيام عمل',
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Process Button
                PrimaryButton(
                  text: 'تأكيد الدفع',
                  onPressed: isProcessing ? null : _processPayment,
                  isLoading: isProcessing,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethod({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required bool isProcessing,
  }) {
    final isSelected = _selectedMethod == method;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                setState(() => _selectedMethod = method);
              },
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isSelected ? AppColors.primary : AppColors.gray300)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.gray500,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: Dimensions.spaceM),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.spaceM,
                              vertical: Dimensions.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? AppColors.info).withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: badgeColor ?? AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    await context.read<JoinFlowCubit>().processPayment(
      userId: authState.user.id,
      amount: widget.amount,
      paymentMethod: _selectedMethod.toString().split('.').last,
    );
  }
}
