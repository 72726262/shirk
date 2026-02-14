import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/inputs/primary_text_field.dart';
import 'package:mmm/presentation/widgets/buttons/primary_button.dart';
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:mmm/data/models/user_model.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'client';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepository();
      
      // Create user with email and password
      final user = await authRepo.createUserByAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء المستخدم بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _emailController.clear();
      _passwordController.clear();
      _fullNameController.clear();
      _phoneController.clear();
      setState(() => _selectedRole = 'client');
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنشاء المستخدم: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء مستخدم جديد'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.spaceXL),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.person_add,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  const Text(
                    'إنشاء حساب مستخدم جديد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  const Text(
                    'قم بملء البيانات التالية لإنشاء حساب جديد',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Full Name
                  PrimaryTextField(
                    controller: _fullNameController,
                    label: 'الاسم الكامل',
                    hint: 'أدخل الاسم الكامل',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الاسم الكامل مطلوب';
                      }
                      if (value.length < 3) {
                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Email
                  PrimaryTextField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    hint: 'example@domain.com',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'البريد الإلكتروني غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Phone
                  PrimaryTextField(
                    controller: _phoneController,
                    label: 'رقم الجوال',
                    hint: '05xxxxxxxx',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رقم الجوال مطلوب';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'رقم الجوال يجب أن يحتوي على أرقام فقط';
                      }
                      if (value.length < 9) {
                        return 'رقم الجوال قصير جداً';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Password
                  PrimaryTextField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    hint: 'أدخل كلمة مرور قوية',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'كلمة المرور مطلوبة';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Role Selection
                  const Text(
                    'صلاحيات المستخدم',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  
                  _buildRoleOption(
                    value: 'client',
                    title: 'عميل',
                    subtitle: 'صلاحيات عميل عادي - الاستثمار في المشاريع',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  
                  _buildRoleOption(
                    value: 'admin',
                    title: 'مدير',
                    subtitle: 'صلاحيات إدارية - إدارة المشاريع والعملاء',
                    icon: Icons.admin_panel_settings,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  
                  _buildRoleOption(
                    value: 'super_admin',
                    title: 'مدير عام',
                    subtitle: 'صلاحيات كاملة - الوصول لجميع الميزات',
                    icon: Icons.supervisor_account,
                  ),
                  
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Create Button
                  PrimaryButton(
                    text: 'إنشاء المستخدم',
                    onPressed: _createUser,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: Dimensions.spaceL),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: Dimensions.spaceS),
                        Expanded(
                          child: Text(
                            'سيتم إنشاء حساب ومحفظة تلقائياً للمستخدم الجديد',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(Dimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedRole,
              onChanged: (val) => setState(() => _selectedRole = val!),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: Dimensions.spaceS),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: Dimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXS),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
