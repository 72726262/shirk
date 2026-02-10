// lib/presentation/screens/auth/verify_phone_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart'; // أضف هذا الاستيراد
import 'package:mmm/routes/route_names.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

class VerifyPhoneScreen extends StatefulWidget {
  final String phoneNumber;

  const VerifyPhoneScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  int _countdown = 60;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _verifyCode(String code) {
    context.read<AuthCubit>().verifyPhone(code);
  }

  void _resendCode() {
    context.read<AuthCubit>().resendPhoneVerificationCode();
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تأكيد رقم الجوال'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is PhoneVerified) {
            Navigator.pushReplacementNamed(context, RouteNames.kycVerification);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is CodeResent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إعادة إرسال الرمز'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Column(
              children: [
                const SizedBox(height: Dimensions.spaceXXL),

                // Phone Icon with Pulse Animation
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smartphone,
                      size: 50,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL * 2),

                // Title
                Text(
                  'أدخل رمز التأكيد',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Subtitle
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'أرسلنا رمز مكون من 6 أرقام إلى\n'),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL * 2),

                // PIN Input
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _pinController,
                    animationType: AnimationType.scale,
                    enabled: !isLoading,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      fieldHeight: 56,
                      fieldWidth: 48,
                      activeFillColor: AppColors.white,
                      selectedFillColor: AppColors.white,
                      inactiveFillColor: AppColors.white,
                      activeColor: AppColors.primary,
                      selectedColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      borderWidth: 2,
                    ),
                    cursorColor: AppColors.primary,
                    animationDuration: const Duration(milliseconds: 300),
                    enableActiveFill: true,
                    keyboardType: TextInputType.number,
                    onCompleted: (pin) {
                      if (!isLoading) {
                        _verifyCode(pin);
                      }
                    },
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Countdown / Resend
                if (_countdown > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      Text(
                        'إعادة الإرسال بعد $_countdown ثانية',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                else
                  TextButton.icon(
                    onPressed: isLoading ? null : _resendCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة إرسال الرمز'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: Dimensions.spaceXXL * 2),

                // Verify Button
                PrimaryButton(
                  text: 'تأكيد',
                  onPressed: _pinController.text.length == 6 && !isLoading
                      ? () => _verifyCode(_pinController.text)
                      : null,
                  isLoading: isLoading,
                  leadingIcon: Icons.check_circle,
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Change Number
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('تغيير رقم الجوال'),
                ),

                const SizedBox(height: Dimensions.spaceXXL),

                // Info Box
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
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: Dimensions.spaceM),
                      Expanded(
                        child: Text(
                          'لم تستلم الرمز؟ تحقق من رسائلك أو اتصل بالدعم الفني',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.info, height: 1.4),
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
    );
  }
}
