import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/core/enums/user_role.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  UserRole _selectedRole = UserRole.client; // Default to client
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkSavedRateLimit();
  }

  Future<void> _checkSavedRateLimit() async {
    final cubit = context.read<AuthCubit>();
    await cubit.checkSavedRateLimit();
    _checkRateLimit();
  }

  void _checkRateLimit() {
    final cubit = context.read<AuthCubit>();
    if (cubit.rateLimitExpiry != null) {
      final now = DateTime.now();
      if (cubit.rateLimitExpiry!.isAfter(now)) {
        final remaining = cubit.rateLimitExpiry!.difference(now).inSeconds;
        _startTimer(remaining);
      }
    }
  }

  void _startTimer(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
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
          if (state is AuthRateLimitExceeded) {
             _startTimer(state.retryAfterSeconds);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            size: 40,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceS),
                        Text(
                          'انضم لرحلة الاستثمار العقاري الذكي',
                          style: TextStyle(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceXL),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'الاسم الكامل',
                          hint: 'أدخل اسمك الثلاثي',
                          icon: Icons.person,
                          enabled: _remainingSeconds == 0,
                        ),

                        const SizedBox(height: Dimensions.spaceL),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          hint: 'example@email.com',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          enabled: _remainingSeconds == 0,
                        ),

                        const SizedBox(height: Dimensions.spaceL),

                        // Phone Field
                        _buildTextField(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          hint: '01XXXXXXXXX',
                          icon: Icons.phone,
                          keyboardType: TextInputType.number,
                          enabled: _remainingSeconds == 0,
                        ),

                        const SizedBox(height: Dimensions.spaceL),

                        const SizedBox(height: Dimensions.spaceL),

                        // Password Field
                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          hint: 'أدخل كلمة المرور',
                          obscureText: _obscurePassword,
                          enabled: _remainingSeconds == 0,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(height: Dimensions.spaceS),

                        // Password Strength
                        _buildPasswordStrength(),

                        const SizedBox(height: Dimensions.spaceL),

                        // Confirm Password Field
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'تأكيد كلمة المرور',
                          hint: 'أعد إدخال كلمة المرور',
                          obscureText: _obscureConfirmPassword,
                          enabled: _remainingSeconds == 0,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),

                        const SizedBox(height: Dimensions.spaceL),

                        // Terms Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value!;
                                });
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusS,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'أوافق على الشروط والأحكام وسياسة الخصوصية',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: Dimensions.spaceXS),
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          // Show terms
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                        ),
                                        child: const Text(
                                          'قراءة الشروط',
                                          style: TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' و ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Show privacy policy
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(50, 30),
                                        ),
                                        child: const Text(
                                          'سياسة الخصوصية',
                                          style: TextStyle(
                                            fontSize: 12,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: Dimensions.spaceXL),

                        // Register Button OR Timer
                        if (_remainingSeconds > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.spaceM),
                            decoration: BoxDecoration(
                              color: AppColors.gray200,
                              borderRadius:
                                  BorderRadius.circular(Dimensions.radiusL),
                              border: Border.all(color: AppColors.gray300),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'الرجاء الانتظار قبل المحاولة مرة أخرى',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: Dimensions.spaceS),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer_outlined,
                                        color: AppColors.primary),
                                    const SizedBox(width: Dimensions.spaceS),
                                    Text(
                                      _formatDuration(_remainingSeconds),
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          PrimaryButton(
                            onPressed: _acceptTerms && !isLoading
                                ? _register
                                : null,
                            text: 'إنشاء حساب',
                            isLoading: isLoading,
                          ),


                        const SizedBox(height: Dimensions.spaceL),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: Dimensions.spaceS),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: Dimensions.spaceXS),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.gray100,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: enabled ? AppColors.primary : AppColors.gray500),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
                vertical: Dimensions.spaceM,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: Dimensions.spaceXS),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.gray100,
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              prefixIcon: Icon(Icons.lock, color: enabled ? AppColors.primary : AppColors.gray500),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHint,
                ),
                onPressed: enabled ? onToggleVisibility : null,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
                vertical: Dimensions.spaceM,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'قوة كلمة المرور',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: Dimensions.spaceXS),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.6,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Dimensions.spaceS),
            const Text(
              'متوسطة',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF4B2B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.spaceXS),
        Wrap(
          spacing: Dimensions.spaceS,
          children: [
            _buildRequirement(Icons.check, '8 أحرف على الأقل', true),
            _buildRequirement(Icons.check, 'حرف كبير', true),
            _buildRequirement(Icons.close, 'رقم', false),
            _buildRequirement(Icons.close, 'رمز خاص', false),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(IconData icon, String text, bool met) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: met ? AppColors.success : AppColors.error),
        const SizedBox(width: Dimensions.spaceXS),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: met ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _register() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      // Validation logic
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمة المرور وتأكيدها غير متطابقتين'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Call AuthCubit for registration
      context.read<AuthCubit>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: 'client', // Force client role
      );
    }
  }
}
