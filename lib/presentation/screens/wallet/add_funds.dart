import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';

class AddFundsScreen extends StatefulWidget {
  const AddFundsScreen({super.key});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'bank_transfer';
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة رصيد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الرصيد الحالي',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceXS),
                        const Text(
                          '150,000 ج.م',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'متاح للسحب: 105,000 ج.م',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spaceXL),

            // Amount Input
            CustomTextField(
              controller: _amountController,
              label: 'المبلغ المطلوب إضافته',
              hint: 'أدخل المبلغ بالجنيه المصري',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: Dimensions.spaceL),

            // Quick Amount Buttons
            const Text(
              'أرقام سريعة',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Dimensions.spaceM),
            Wrap(
              spacing: Dimensions.spaceM,
              runSpacing: Dimensions.spaceM,
              children: ['500', '1,000', '5,000', '10,000', '25,000', '50,000']
                  .map((amount) {
                    return ActionChip(
                      label: Text('$amount ج.م'),
                      onPressed: () {
                        _amountController.text = amount.replaceAll(',', '');
                      },
                      backgroundColor: AppColors.surface,
                      labelStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  })
                  .toList(),
            ),

            const SizedBox(height: Dimensions.spaceXL),

            // Payment Method
            const Text(
              'طريقة الدفع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Payment Methods List
            Column(
              children: [
                _buildPaymentMethod(
                  value: 'bank_transfer',
                  title: 'تحويل بنكي',
                  subtitle: 'تحويل مباشر من حسابك البنكي',
                  icon: Icons.account_balance,
                  isSelected: _selectedMethod == 'bank_transfer',
                ),
                _buildPaymentMethod(
                  value: 'credit_card',
                  title: 'بطاقة ائتمان',
                  subtitle: 'فيزا / ماستركارد',
                  icon: Icons.credit_card,
                  isSelected: _selectedMethod == 'credit_card',
                ),
                _buildPaymentMethod(
                  value: 'wallet',
                  title: 'محفظة رقمية',
                  subtitle: 'فودافون كاش / أورنج كاش',
                  icon: Icons.phone_android,
                  isSelected: _selectedMethod == 'wallet',
                ),
              ],
            ),

            // Card Details (if credit card selected)
            if (_selectedMethod == 'credit_card') ...[
              const SizedBox(height: Dimensions.spaceXL),
              const Text(
                'تفاصيل البطاقة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),

              Column(
                children: [
                  CustomTextField(
                    controller: _cardNumberController,
                    label: 'رقم البطاقة',
                    hint: '1234 5678 9012 3456',
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _expiryDateController,
                          label: 'تاريخ الانتهاء',
                          hint: 'MM/YY',
                          keyboardType: TextInputType.datetime,
                          maxLength: 5,
                        ),
                      ),
                      const SizedBox(width: Dimensions.spaceL),
                      Expanded(
                        child: CustomTextField(
                          controller: _cvvController,
                          label: 'CVV',
                          hint: '123',
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  CustomTextField(
                    controller: _cardHolderController,
                    label: 'اسم حامل البطاقة',
                    hint: 'كما هو مدون على البطاقة',
                  ),
                ],
              ),
            ],

            // Bank Transfer Instructions (if bank transfer selected)
            if (_selectedMethod == 'bank_transfer') ...[
              const SizedBox(height: Dimensions.spaceXL),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعليمات التحويل البنكي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    _buildBankDetail(
                      title: 'اسم البنك',
                      value: 'البنك الأهلي المصري',
                    ),
                    _buildBankDetail(
                      title: 'رقم الحساب',
                      value: '123456789012345',
                    ),
                    _buildBankDetail(
                      title: 'IBAN',
                      value: 'EG123456789012345678901234',
                    ),
                    _buildBankDetail(
                      title: 'اسم المستفيد',
                      value: 'شركة شريك العقاري',
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text(
                      'ملاحظات هامة:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceS),
                    const Text(
                      '1. أضف رقم هاتفك في ملاحظات التحويل\n'
                      '2. سيتم إضافة الرصيد خلال 24 ساعة عمل\n'
                      '3. احتفظ بصورة إيصال التحويل',
                      style: TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: Dimensions.spaceXL),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ElevatedButton(
          onPressed: () {
            _processPayment();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
          ),
          child: const Text(
            'تأكيد الإيداع',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: Dimensions.spaceL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: Dimensions.spaceXS),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetail({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال مبلغ صحيح'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show payment processing dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد عملية الإيداع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('المبلغ: ${amount.toStringAsFixed(2)} ج.م'),
              Text('الطريقة: ${_getPaymentMethodName(_selectedMethod)}'),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'هل أنت متأكد من عملية الإيداع؟',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'تحويل بنكي';
      case 'credit_card':
        return 'بطاقة ائتمان';
      case 'wallet':
        return 'محفظة رقمية';
      default:
        return 'غير محدد';
    }
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                const Text(
                  'تمت العملية بنجاح!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'تم إضافة ${_amountController.text} ج.م إلى محفظتك',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'رقم المرجع: REF${DateTime.now().millisecondsSinceEpoch}',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('تم'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
