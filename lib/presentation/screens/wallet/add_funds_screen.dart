import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:intl/intl.dart';

enum TopUpMethod { bankTransfer, creditCard, applePay, stcPay }

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  TopUpMethod _selectedMethod = TopUpMethod.creditCard;

  final List<double> _quickAmounts = [1000, 5000, 10000, 25000, 50000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إضافة رصيد'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletTransactionCreated) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تمت إضافة الرصيد بنجاح'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isProcessing = state is WalletLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceXXL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.white,
                        size: 48,
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      Text(
                        'شحن المحفظة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Text(
                        'أضف رصيد لمحفظتك للمشاركة في المشاريع',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Amount Input
                Text(
                  'المبلغ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),
                CustomTextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  hint: '0',
                  label: 'المبلغ',
                  enabled: !isProcessing,
                  suffixIcon: Icon(Icons.money),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    if (amount == null || amount < 100) {
                      return 'الحد الأدنى 100 ر.س';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Quick Amount Buttons
                Wrap(
                  spacing: Dimensions.spaceM,
                  runSpacing: Dimensions.spaceM,
                  children: _quickAmounts.map((amount) {
                    return _buildQuickAmountChip(
                      amount,
                      currency,
                      isProcessing,
                    );
                  }).toList(),
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
                  method: TopUpMethod.creditCard,
                  icon: Icons.credit_card,
                  title: 'بطاقة ائتمان',
                  subtitle: 'Visa, Mastercard, Mada',
                  badge: 'فوري',
                  badgeColor: AppColors.success,
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceM),

                _buildPaymentMethod(
                  method: TopUpMethod.applePay,
                  icon: Icons.apple,
                  title: 'Apple Pay',
                  subtitle: 'دفع سريع وآمن',
                  badge: 'مستحسن',
                  badgeColor: AppColors.primary,
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceM),

                _buildPaymentMethod(
                  method: TopUpMethod.stcPay,
                  icon: Icons.phone_android,
                  title: 'STC Pay',
                  subtitle: 'الدفع عبر تطبيق STC Pay',
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceM),

                _buildPaymentMethod(
                  method: TopUpMethod.bankTransfer,
                  icon: Icons.account_balance,
                  title: 'تحويل بنكي',
                  subtitle: 'يستغرق 1-3 أيام عمل',
                  isProcessing: isProcessing,
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Fees Notice
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: Dimensions.spaceM),
                      Expanded(
                        child: Text(
                          'لا توجد رسوم إضافية على عمليات الإيداع',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Add Funds Button
                PrimaryButton(
                  text: 'متابعة',
                  onPressed: _canProceed() && !isProcessing
                      ? _processFunds
                      : null,
                  isLoading: isProcessing,
                  leadingIcon: Icons.arrow_forward,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAmountChip(
    double amount,
    NumberFormat currency,
    bool isProcessing,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                setState(() {
                  _amountController.text = amount.toInt().toString();
                });
              },
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.spaceL,
            vertical: Dimensions.spaceM,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            currency.format(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required TopUpMethod method,
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
                      color: AppColors.primary.withValues(alpha: 0.1),
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
                      .withValues(alpha: 0.1),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
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
                              color: (badgeColor ?? AppColors.info).withValues(
                                alpha: 0.1,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  bool _canProceed() {
    final amount = double.tryParse(_amountController.text);
    return amount != null && amount >= 100;
  }

  Future<void> _processFunds() async {
    if (!_canProceed()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final amount = double.parse(_amountController.text);

    await context.read<WalletCubit>().createDeposit(
      userId: authState.user.id,
      amount: amount,
      paymentMethod: _selectedMethod.toString().split('.').last,
    );
  }
}
