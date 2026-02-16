import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/routes/route_names.dart';

enum PaymentPlan { full, installments }

class ContractSummaryScreen extends StatefulWidget {
  final String projectId;
  final String unitId;

  const ContractSummaryScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  @override
  State<ContractSummaryScreen> createState() => _ContractSummaryScreenState();
}

class _ContractSummaryScreenState extends State<ContractSummaryScreen> {
  PaymentPlan _selectedPlan = PaymentPlan.installments;
  bool _agreeToTerms = false;
  bool _agreeToDataPrivacy = false;
  bool _acceptAutoPayments = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملخص العقد')),
      body: BlocConsumer<JoinFlowCubit, JoinFlowState>(
        listener: (context, state) {
          if (state is ContractAccepted) {
            Navigator.pushNamed(
              context,
              RouteNames.payment,
              arguments: {
                'subscriptionId': state.subscriptionId,
                'amount': state.amount,
              },
            );
          }
          if (state is JoinFlowError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
            final selectedUnit = context.read<JoinFlowCubit>().selectedUnit;
            // if (state is UnitSelectionState) {
            //    selectedUnit = state.selectedUnit;
            // }
            
            final unitNumber = selectedUnit?.unitNumber ?? widget.unitId;
            final double unitPrice = selectedUnit?.price ?? 0.0;
            
            // Financial Calculations
            double payNowAmount = 0.0;
            double futureInstallmentAmount = 0.0;
            int installmentsCount = 0;

            if (_selectedPlan == PaymentPlan.full) {
              payNowAmount = unitPrice;
              futureInstallmentAmount = 0.0;
              installmentsCount = 0;
            } else {
              // 4 Equal Installments
              payNowAmount = unitPrice / 4;
              futureInstallmentAmount = unitPrice / 4;
              installmentsCount = 3;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Container(
                  color: AppColors.background, 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Summary
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ملخص المشروع',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: Dimensions.spaceL),
                            _buildSummaryItem(
                              title: 'رقم المشروع',
                              value: widget.projectId,
                            ),
                            _buildSummaryItem(
                              title: 'رقم الوحدة',
                              value: unitNumber,
                            ),
                            if (selectedUnit != null) ...[
                              _buildSummaryItem(
                                title: 'المساحة',
                                value: '${selectedUnit.areaSqm} م²',
                              ),
                              _buildSummaryItem(
                                title: 'السعر الإجمالي',
                                value: '${unitPrice.toStringAsFixed(0)} ر.س',
                              ),
                            ],
                          ],
                        ),
                      ),
            
                      const SizedBox(height: Dimensions.spaceXL),
            
                      // Payment Plan Selection
                      const Text(
                        'خطة الدفع',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPlanOption(
                              label: 'دفع كامل',
                              value: PaymentPlan.full,
                              description: 'دفعة واحدة (100%)',
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: _buildPlanOption(
                              label: 'تقسيط',
                              value: PaymentPlan.installments,
                              description: '4 دفعات متساوية',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceXL),
            
                      // Financial Summary
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPlan == PaymentPlan.full ? 'تفاصيل الدفع الكامل' : 'تفاصيل التقسيط (4 دفعات)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: Dimensions.spaceL),
                            _buildFinancialItem(
                              title: 'المطلوب دفعه الآن (الدفعة الأولى)',
                              value: '${payNowAmount.toStringAsFixed(0)} ر.س',
                              isBold: true,
                            ),
                            if (_selectedPlan == PaymentPlan.installments) ...[
                              const Divider(height: Dimensions.spaceM),
                              _buildFinancialItem(
                                title: 'عدد الدفعات المتبقية',
                                value: '$installmentsCount دفعات',
                                isBold: false,
                              ),
                              _buildFinancialItem(
                                title: 'قيمة الدفعة القادمة',
                                value: '${futureInstallmentAmount.toStringAsFixed(0)} ر.س',
                                isBold: false,
                              ),
                            ],
                            const Divider(height: Dimensions.spaceXL),
                            _buildFinancialItem(
                              title: 'المجموع الكلي',
                              value: '${unitPrice.toStringAsFixed(0)} ر.س',
                              isBold: true,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
            
                      const SizedBox(height: Dimensions.spaceXL),
            
                      // Terms and Conditions
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الشروط والأحكام',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: Dimensions.spaceL),
            
                            // Contract Terms Text
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(Dimensions.spaceL),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(Dimensions.radiusM),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _contractTerms,
                                  style: const TextStyle(fontSize: 13, height: 1.5),
                                ),
                              ),
                            ),
            
                            const SizedBox(height: Dimensions.spaceL),
            
                            // Agreement Checkboxes
                            Column(
                              children: [
                                _buildAgreementCheckbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) => setState(() => _agreeToTerms = value!),
                                  text: 'أوافق على الشروط والأحكام المذكورة أعلاه',
                                ),
                                _buildAgreementCheckbox(
                                  value: _agreeToDataPrivacy,
                                  onChanged: (value) => setState(() => _agreeToDataPrivacy = value!),
                                  text: 'أوافق على سياسة الخصوصية ومعالجة البيانات',
                                ),
                                _buildAgreementCheckbox(
                                  value: _acceptAutoPayments,
                                  onChanged: (value) => setState(() => _acceptAutoPayments = value!),
                                  text: 'أوافق على خصم الأقساط تلقائياً من محفظتي',
                                  isOptional: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
            
                      const SizedBox(height: Dimensions.spaceXL),
                    ],
                  ),
                ),
            );
          },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('رجوع'),
              ),
            ),
            const SizedBox(width: Dimensions.spaceL),
            Expanded(
              child: ElevatedButton(
                onPressed: _agreeToTerms && _agreeToDataPrivacy
                    ? () {
                         context.read<JoinFlowCubit>().acceptContract(
                           widget.projectId,
                           widget.unitId,
                           isFullPayment: _selectedPlan == PaymentPlan.full,
                         );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppColors.gray300,
                ),
                child: const Text('متابعة للدفع'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanOption({
    required String label,
    required PaymentPlan value,
    required String description,
  }) {
    final isSelected = _selectedPlan == value;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = value),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFinancialItem({
    required String title,
    required String value,
    required bool isBold,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color ?? AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    bool isOptional = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: Dimensions.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 14)),
                if (isOptional)
                  Text(
                    '(اختياري)',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final String _contractTerms = '''
مادة (1): أحكام عامة
1.1. يلتزم الطرفان بأحكام هذا العقد والشروط المرفقة.
1.2. يعتبر هذا العقد نافذاً من تاريخ توقيعه من الطرفين.

مادة (2): الالتزامات المالية
2.1. يلتزم المستثمر بسداد الدفعة الأولى أو كامل المبلغ حسب الخطة المختارة.
2.2. في حالة التقسيط، يتم سداد المبلغ المتبقي على 3 دفعات إضافية متساوية.
2.3. يلتزم المطور بتسليم الوحدة وفق المواصفات المتفق عليها.

مادة (3): ضمانات المطور
3.1. يضمن المطور جودة المواد المستخدمة وفق المواصفات القياسية.
3.2. يتحمل المطور مسؤولية العيوب الإنشائية لمدة 10 سنوات.
3.3. يلتزم المطور بجدول التنفيذ المتفق عليه.

مادة (4): التزامات المستثمر
4.1. يلتزم المستثمر بسداد الأقساط في مواعيدها المحددة.
4.2. يحق للمطور تطبيق غرامة تأخير في حالة عدم السداد في الموعد.

مادة (5): التسليم والاستلام
5.1. يتم تسليم الوحدة عند اكتمالها وفق المواصفات المتفق عليها.
5.2. يتم إعداد محضر استلام مشترك بين الطرفين.
''';
}
