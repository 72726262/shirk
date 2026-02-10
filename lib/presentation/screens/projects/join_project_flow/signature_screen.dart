import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';

import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/widgets/custom/signature_pad.dart';
import 'package:mmm/routes/route_names.dart';

class SignatureScreen extends StatefulWidget {
  final String subscriptionId;

  const SignatureScreen({super.key, required this.subscriptionId});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final GlobalKey<SignaturePadWidgetState> _signatureKey = GlobalKey();
  Uint8List? _signatureData;
  bool _hasSignature = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: BlocConsumer<JoinFlowCubit, JoinFlowState>(
        listener: (context, state) {
          if (state is JoinFlowCompleted) {
            _navigateToConfirmation(context);
          }
          if (state is JoinFlowError) {
            _showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          final isSubmitting = state is JoinFlowLoading;

          return Column(
            children: [
              _buildHeaderSection(),
              _buildSignatureSection(context),
              _buildBottomSection(isSubmitting),
            ],
          );
        },
      ),
    );
  }

  // 🔽 AppBar مخصصة
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('التوقيع الإلكتروني'),
      backgroundColor: AppColors.primary,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_hasSignature)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearSignature,
            tooltip: 'مسح التوقيع',
          ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
        ),
      ),
    );
  }

  // 🔽 قسم الرأس
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceXXL,
        vertical: Dimensions.spaceXL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.primary.withOpacity(0.02),
          ],
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
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(Icons.draw_rounded, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: Dimensions.spaceL),
          Text(
            'التوقيع الإلكتروني',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.spaceM),
          Text(
            'قم بالتوقيع في المساحة المخصصة أدناه لإتمام عملية الاشتراك',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🔽 قسم التوقيع
  Widget _buildSignatureSection(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.spaceXXL),
        child: Column(
          children: [
            // بطاقة التوقيع الرئيسية
            _buildSignatureCard(context),
            const SizedBox(height: Dimensions.spaceXXL),

            // معلومات مساعدة
            _buildInfoCards(context),
          ],
        ),
      ),
    );
  }

  // 🔽 بطاقة التوقيع
  Widget _buildSignatureCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusXL),
                topRight: Radius.circular(Dimensions.radiusXL),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: Dimensions.spaceM),
                Expanded(
                  child: Text(
                    'منطقة التوقيع',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  _hasSignature ? '✓ تم التوقيع' : 'بانتظار توقيعك',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hasSignature
                        ? AppColors.success
                        : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 280,
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: SignaturePadWidget(
              key: _signatureKey,
              width: double.infinity,
              height: 260,
              onSigned: (signatureBytes) {
                setState(() {
                  _signatureData = signatureBytes;
                  _hasSignature =
                      signatureBytes != null && signatureBytes.isNotEmpty;
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(Dimensions.radiusXL),
                bottomRight: Radius.circular(Dimensions.radiusXL),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إعادة التوقيع'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                  ),
                ),
                if (_signatureData != null)
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      child: Image.memory(_signatureData!, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔽 بطاقات المعلومات
  Widget _buildInfoCards(BuildContext context) {
    return Column(
      children: [
        // بطاقة المعلومات القانونية
        Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.05),
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.gavel_rounded,
                  size: 16,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قيمة قانونية كاملة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      'التوقيع الإلكتروني له نفس القوة القانونية للتوقيع الورقي وفقاً لأنظمة المملكة',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.spaceM),

        // بطاقة الأمان
        Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.05),
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.success.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'توقيع آمن',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      'توقيعك يتم حفظه بشكل مشفر وآمن، ولا يمكن لأحد الوصول إليه',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔽 القسم السفلي
  Widget _buildBottomSection(bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusXL),
          topRight: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _hasSignature ? Icons.check_circle : Icons.info_outline,
                  size: 18,
                  color: _hasSignature
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: Dimensions.spaceM),
                Expanded(
                  child: Text(
                    _hasSignature
                        ? 'التوقيع جاهز! يمكنك المتابعة'
                        : 'يرجى التوقيع أولاً للمتابعة',
                    style: TextStyle(
                      fontSize: 13,
                      color: _hasSignature
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spaceL),
            PrimaryButton(
              text: 'تأكيد التوقيع والمتابعة',
              onPressed: _hasSignature && !isSubmitting
                  ? () => _submitSignature()
                  : null,
              isLoading: isSubmitting,
              leadingIcon: Icons.arrow_forward_rounded,
              fullWidth: true,
              backgroundColor: _hasSignature
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3),
              foregroundColor: _hasSignature
                  ? AppColors.white
                  : AppColors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceXXL,
                vertical: Dimensions.spaceL,
              ),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            if (!_hasSignature)
              Padding(
                padding: const EdgeInsets.only(top: Dimensions.spaceM),
                child: Text(
                  'سيتم تفعيل الزر بعد التوقيع',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔽 دوال مساعدة
  void _clearSignature() {
    if (_signatureKey.currentState != null) {
      _signatureKey.currentState!.clear();
    }
    setState(() {
      _signatureData = null;
      _hasSignature = false;
    });
  }

  Future<void> _submitSignature() async {
    if (_signatureKey.currentState == null ||
        !_signatureKey.currentState!.hasSignature) {
      _showErrorSnackBar(context, 'يرجى التوقيع أولاً');
      return;
    }

    try {
      final signatureBytes = _signatureKey.currentState!.hasSignature;
      if (signatureBytes == null || signatureBytes != null) {
        throw Exception('توقيع غير صالح');
      }

      await context.read<JoinFlowCubit>().submitSignature(
        subscriptionId: widget.subscriptionId,
        signatureData: signatureBytes.toString(),
      );
    } catch (e) {
      _showErrorSnackBar(context, 'فشل إرسال التوقيع: $e');
    }
  }

  void _navigateToConfirmation(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.joinConfirmation,
      (route) => false,
      arguments: {
        'subscriptionId': widget.subscriptionId,
        'hasSignature': _hasSignature,
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: Dimensions.spaceM),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // دالة للحصول على بيانات التوقيع
  Uint8List? get signatureData => _signatureData;
}
