import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class ESignatureScreen extends StatefulWidget {
  final String subscriptionId;

  const ESignatureScreen({
    super.key,
    required this.subscriptionId,
  });

  @override
  State<ESignatureScreen> createState() => _ESignatureScreenState();
}

class _ESignatureScreenState extends State<ESignatureScreen> {
  Uint8List? _signatureImage;
  bool _isSigning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التوقيع الإلكتروني')),
      body: BlocConsumer<JoinFlowCubit, JoinFlowState>(
        listener: (context, state) {
          if (state is JoinFlowCompleteState) {
            Navigator.pop(context); // Close loading/bottom sheet if open
            _showSignatureSuccess();
          }
          if (state is JoinFlowError) {
            Navigator.pop(context); // Close loading if open
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
          if (state is PaymentProcessingState) {
            // Optional: Loading is shown in UI via isSubmitting
          }
        },
        builder: (context, state) {
          final isSubmitting = state is PaymentProcessingState || state is JoinFlowLoading;

          return SingleChildScrollView(
            child: Column(
              children: [
                if (isSubmitting)
                  const LinearProgressIndicator(),

                // Contract Preview
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.contrast,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      const Text(
                        'عقد شراكة المشروع',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Text(
                        'برج النخيل السكني - الوحدة A101',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Signature Area
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التوقيع الإلكتروني',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Text(
                        'قم بالتوقيع في المنطقة أدناه لتأكيد قبولك للعقد',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: Dimensions.spaceXL),

                      // Signature Pad
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Signature Preview
                            if (_signatureImage != null)
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: Dimensions.spaceL,
                                ),
                                padding: const EdgeInsets.all(Dimensions.spaceL),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusM,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'التوقيع المدخل',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: Dimensions.spaceS),
                                    if (_signatureImage!.isNotEmpty)
                                      Image.memory(
                                        _signatureImage!,
                                        height: 60,
                                        fit: BoxFit.contain,
                                      )
                                    else
                                       const Text('تم التسجيل (محاكاة)'),
                                  ],
                                ),
                              ),

                            // Signature Canvas
                             GestureDetector(
                              onTap: isSubmitting ? null : () {
                                // Mock signature for now
                                 setState(() {
                                  // Create a dummy non-empty list to simulate signature bytes
                                  _signatureImage = Uint8List.fromList(List.generate(100, (index) => index % 255));
                                  _isSigning = true; 
                                });
                              },
                              child: Container(
                                height: 200,
                                color: Colors.grey[100],
                                child: const Center(child: Text('اضغط هنا للتوقيع (محاكاة)')),
                              ),
                             ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Dimensions.spaceXL),

                      // Contract Terms Summary
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
                              'ملخص البنود الرئيسية',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: Dimensions.spaceL),
                            _buildTermItem('المبلغ الإجمالي', '1,200,000 ج.م'),
                            _buildTermItem('الدفعة الأولى', '120,000 ج.م (10%)'),
                            _buildTermItem('مدة السداد', '48 شهراً'),
                            _buildTermItem('القسط الشهري', '22,500 ج.م'),
                            _buildTermItem('تاريخ التسليم المتوقع', 'يونيو 2025'),
                          ],
                        ),
                      ),

                      const SizedBox(height: Dimensions.spaceXL),

                      // Legal Notice
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusL),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel, color: AppColors.warning),
                            const SizedBox(width: Dimensions.spaceL),
                            Expanded(
                              child: Text(
                                'التوقيع الإلكتروني له نفس القوة القانونية للتوقيع اليدوي وفقاً للقوانين المحلية والدولية',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _isSigning,
                  onChanged: (value) {
                    setState(() {
                      _isSigning = value!;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Text(
                    'أقر بأنني قرأت وفهمت جميع بنود العقد وأوافق عليها',
                    style: TextStyle(
                      color: _isSigning
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: _isSigning
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spaceL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSigning
                    ? () {
                        _confirmSignature();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  disabledBackgroundColor: AppColors.gray300,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'تأكيد التوقيع',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isSigning) ...[
                      const SizedBox(width: Dimensions.spaceS),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fingerprint, size: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, String value) {
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

  void _confirmSignature() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Icon(Icons.fingerprint, size: 64, color: AppColors.primary),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'التأكيد الأخير',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'التوقيع الإلكتروني النهائي يتطلب التأكيد باستخدام بصمة الإصبع أو رمز OTP',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Dimensions.spaceXL),
              _buildOtpInput(),
              const SizedBox(height: Dimensions.spaceL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                         // Call Cubit to sign
                         if (_signatureImage != null) {
                           context.read<JoinFlowCubit>().signContractBytes(_signatureImage!);
                           Navigator.pop(context); // Close sheet, wait for listener
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('تأكيد'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
              TextButton(
                onPressed: () {
                  // Use fingerprint instead - Mock
                  if (_signatureImage != null) {
                    context.read<JoinFlowCubit>().signContractBytes(_signatureImage!);
                    Navigator.pop(context); // Close sheet
                  }
                },
                child: const Text('استخدام بصمة الإصبع'),
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: const Center(
            child: Text(
              '•',
              style: TextStyle(fontSize: 32, color: AppColors.primary),
            ),
          ),
        );
      }),
    );
  }

  void _showSignatureSuccess() {
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.check,
                          size: 48,
                          color: AppColors.success,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.contrast,
                            size: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                const Text(
                  'تم التوقيع بنجاح!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'تم حفظ نسخة من العقد الموقع في مركز المستندات',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.file_copy, color: AppColors.primary),
                      const SizedBox(width: Dimensions.spaceS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'عقد الشراكة',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'تم التوقيع في ${DateTime.now().toString().substring(0, 16)}',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      
                      final cubit = context.read<JoinFlowCubit>();
                       Navigator.pushNamed(
                        context,
                        RouteNames.joinConfirmation,
                        arguments: {
                          'projectId': cubit.projectId,
                          'unitId': cubit.selectedUnit?.id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('عرض تفاصيل الاشتراك'),
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
