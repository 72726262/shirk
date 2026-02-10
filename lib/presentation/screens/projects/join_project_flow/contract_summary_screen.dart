import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

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
  bool _agreeToTerms = false;
  bool _agreeToDataPrivacy = false;
  bool _acceptAutoPayments = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملخص العقد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
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
                    title: 'اسم المشروع',
                    value: 'برج النخيل السكني',
                  ),
                  _buildSummaryItem(
                    title: 'الوحدة المختارة',
                    value: 'A101 - شقة 120 م²',
                  ),
                  _buildSummaryItem(
                    title: 'المكان',
                    value: 'حي النخيل، القاهرة الجديدة',
                  ),
                  _buildSummaryItem(
                    title: 'المطور',
                    value: 'شركة النخيل العقارية',
                  ),
                ],
              ),
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
                  const Text(
                    'الملخص المالي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  _buildFinancialItem(
                    title: 'سعر الوحدة',
                    value: '1,200,000 ج.م',
                    isBold: false,
                  ),
                  _buildFinancialItem(
                    title: 'الدفعة الأولى (10%)',
                    value: '120,000 ج.م',
                    isBold: false,
                  ),
                  _buildFinancialItem(
                    title: 'المبلغ المتبقي',
                    value: '1,080,000 ج.م',
                    isBold: false,
                  ),
                  const Divider(height: Dimensions.spaceXL),
                  _buildFinancialItem(
                    title: 'المجموع الكلي',
                    value: '1,200,000 ج.م',
                    isBold: true,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  _buildFinancialItem(
                    title: 'الدفع على 48 شهر',
                    value: '22,500 ج.م / شهرياً',
                    isBold: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spaceXL),

            // Payment Schedule Preview
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
                    'جدول الدفعات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  ...List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                      padding: const EdgeInsets.all(Dimensions.spaceM),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'القسط ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${DateTime.now().add(Duration(days: 30 * index)).day}/${DateTime.now().add(Duration(days: 30 * index)).month}/${DateTime.now().add(Duration(days: 30 * index)).year}',
                                style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '22,500 ج.م',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    child: TextButton(
                      onPressed: () {
                        // Show full payment schedule
                      },
                      child: const Text('عرض جدول الدفعات الكامل'),
                    ),
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

                  // Contract Terms
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
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value!;
                          });
                        },
                        text: 'أوافق على الشروط والأحكام المذكورة أعلاه',
                      ),
                      _buildAgreementCheckbox(
                        value: _agreeToDataPrivacy,
                        onChanged: (value) {
                          setState(() {
                            _agreeToDataPrivacy = value!;
                          });
                        },
                        text: 'أوافق على سياسة الخصوصية ومعالجة البيانات',
                      ),
                      _buildAgreementCheckbox(
                        value: _acceptAutoPayments,
                        onChanged: (value) {
                          setState(() {
                            _acceptAutoPayments = value!;
                          });
                        },
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
                        Navigator.pushNamed(
                          context,
                          '/payment',
                          arguments: {
                            'projectId': widget.projectId,
                            'unitId': widget.unitId,
                          },
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

  Widget _buildSummaryItem({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: AppColors.textSecondary)),
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
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
2.1. يلتزم المستثمر بسداد الدفعة الأولى بنسبة 10% من إجمالي قيمة الوحدة.
2.2. يتم سداد المبلغ المتبقي على أقساط شهرية لمدة 48 شهراً.
2.3. يلتزم المطور بتسليم الوحدة وفق المواصفات المتفق عليها.

مادة (3): ضمانات المطور
3.1. يضمن المطور جودة المواد المستخدمة وفق المواصفات القياسية.
3.2. يتحمل المطور مسؤولية العيوب الإنشائية لمدة 10 سنوات.
3.3. يلتزم المطور بجدول التنفيذ المتفق عليه.

مادة (4): التزامات المستثمر
4.1. يلتزم المستثمر بسداد الأقساط في مواعيدها المحددة.
4.2. يحق للمطور تطبيق غرامة تأخير في حالة عدم السداد في الموعد.
4.3. يحق للمستثمر متابعة سير العمل وفق الآليات المحددة.

مادة (5): التسليم والاستلام
5.1. يتم تسليم الوحدة عند اكتمالها وفق المواصفات المتفق عليها.
5.2. يتم إعداد محضر استلام مشترك بين الطرفين.
5.3. يتم صيانة العيوب الظاهرة خلال سنة من تاريخ التسليم.

مادة (6): أحكام ختامية
6.1. يحق لأي من الطرفين إنهاء العقد في حالة الإخلال الجسيم.
6.2. يتم تسوية أي نزاعات عن طريق التحكيم.
6.3. يعتبر هذا العقد سارياً في جميع أحكامه.

بتوقيع هذا العقد، يقر الطرفان باطلاعهما على جميع بنوده وموافقتهما عليها.
''';
}
