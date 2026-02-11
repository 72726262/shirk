import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/core/utils/dashboard_router.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.9),
                AppColors.primary.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: AppColors.white,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.spaceXXL),
        // Animated Title
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'مرحباً ',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    TextSpan(
                      text: 'بعودتك',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spaceS),
              Text(
                'سجل دخولك للمتابعة',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field with enhanced design
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomTextField(
            label: 'البريد الإلكتروني',
            hint: 'example@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            prefixIconColor: AppColors.primary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              borderSide: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'البريد الإلكتروني غير صحيح';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: Dimensions.spaceXL),

        // Password Field with toggle visibility
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomTextField(
            label: 'كلمة المرور',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            prefixIconColor: AppColors.primary,
            textInputAction: TextInputAction.done,
            suffixIconWidget: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              borderSide: BorderSide(
                color: AppColors.border.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال كلمة المرور';
              }
              if (value.length < 6) {
                return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Container(
      margin: const EdgeInsets.only(top: Dimensions.spaceM),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: InkWell(
          onTap: () {
            // TODO: Navigate to forgot password
          },
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.spaceL,
              vertical: Dimensions.spaceS,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(width: Dimensions.spaceS),
                Text(
                  'نسيت كلمة المرور؟',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const SizedBox(height: Dimensions.spaceXL),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
              ),
              child: Text(
                'أو سجل دخول باستخدام',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: Dimensions.spaceXL),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              color: Colors.red,
              onTap: () {},
            ),
            const SizedBox(width: Dimensions.spaceXL),
            _buildSocialButton(
              icon: Icons.facebook,
              color: Colors.blue,
              onTap: () {},
            ),
            const SizedBox(width: Dimensions.spaceXL),
            _buildSocialButton(
              icon: Icons.apple,
              color: Colors.black,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusL),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Container(
      margin: const EdgeInsets.only(top: Dimensions.spaceXL),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        borderRadius: BorderRadius.circular(Dimensions.radiusCircle),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ليس لديك حساب؟ ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, RouteNames.register);
              },
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceS,
                  vertical: Dimensions.spaceXS,
                ),
                child: Row(
                  children: [
                    Text(
                      'إنشاء حساب جديد',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceXS),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              // ✅ Always go to dashboard - let dashboard show approval dialog
              final dashboardRoute = DashboardRouter.getDashboardRoute(state.role);
              Navigator.pushReplacementNamed(context, dashboardRoute);
            }
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.white),
                      const SizedBox(width: Dimensions.spaceS),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(Dimensions.spaceXXL),
                  children: [
                    const SizedBox(height: Dimensions.space3XL),
                    _buildLogoSection(),
                    const SizedBox(height: Dimensions.space4XL),
                    _buildLoginForm(),
                    _buildForgotPassword(),
                    const SizedBox(height: Dimensions.space3XL),
                    PrimaryButton(
                      text: 'تسجيل الدخول',
                      onPressed: _handleLogin,
                      isLoading: isLoading,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      height: 56,
                    ),
                    _buildSocialLogin(),
                    const SizedBox(height: 10),
                    _buildSignUpLink(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// إضافة Enum لـ KYCStatus هنا إذا لم يكن موجوداً في مكان آخر
enum KYCStatus { pending, underReview, approved, rejected }
