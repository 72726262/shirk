import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:intl/intl.dart';

class WithdrawFundsScreen extends StatefulWidget {
  const WithdrawFundsScreen({super.key});

  @override
  State<WithdrawFundsScreen> createState() => _WithdrawFundsScreenState();
}

class _WithdrawFundsScreenState extends State<WithdrawFundsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _ibanController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _ibanController.dispose();
    _beneficiaryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سحب رصيد'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletTransactionCreated) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تقديم طلب السحب بنجاح'),
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
          final availableBalance = state is WalletLoaded
              ? state.wallet.balance - state.wallet.reservedBalance
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceXXL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.error.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.3),
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
                          'سحب من المحفظة',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: Dimensions.spaceM),
                        Text(
                          'الرصيد المتاح للسحب',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currency.format(availableBalance),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Amount Input
                  CustomTextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    label: 'المبلغ',
                    hint: '0',
                    enabled: !isProcessing,
                    prefixIcon: Icons.money,
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount < 100) {
                        return 'الحد الأدنى 100 ر.س';
                      }
                      if (amount > availableBalance) {
                        return 'الرصيد غير كافِ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // IBAN Input
                  CustomTextField(
                    controller: _ibanController,
                    label: 'رقم الآيبان (IBAN)',
                    hint: 'SA00 0000 0000 0000 0000 0000',
                    enabled: !isProcessing,
                    prefixIcon: Icons.account_balance,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم الآيبان';
                      }
                      if (!value.startsWith('SA') || value.length < 22) {
                        return 'رقم الآيبان غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Beneficiary Name
                  CustomTextField(
                    controller: _beneficiaryNameController,
                    label: 'اسم المستفيد',
                    hint: 'الاسم كما يظهر في الحساب البنكي',
                    enabled: !isProcessing,
                    prefixIcon: Icons.person,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال اسم المستفيد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            const SizedBox(width: Dimensions.spaceM),
                            Expanded(
                              child: Text(
                                'مدة التحويل: 1-3 أيام عمل',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceM),
                        Row(
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
                                'لا توجد رسوم على عمليات السحب',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Withdraw Button
                  PrimaryButton(
                    text: 'تقديم طلب السحب',
                    onPressed: !isProcessing ? _processWithdrawal : null,
                    isLoading: isProcessing,
                    leadingIcon: Icons.send,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    final amount = double.parse(_amountController.text);

    await context.read<WalletCubit>().createWithdrawal(
      userId: authState.user.id,
      amount: amount,
      iban: _ibanController.text.trim(),
    );
  }
}
