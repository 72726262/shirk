import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/cubits/profile/profile_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _nameController.text = authState.user.fullName;
      _phoneController.text = authState.user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث الملف الشخصي بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProfileLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          _nameController.text.isNotEmpty ? _nameController.text[0] : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.spaceS),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Form Fields
                  CustomTextField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    prefixIcon: Icons.person,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  CustomTextField(
                    controller: _phoneController,
                    label: 'رقم الجوال',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Save Button
                  PrimaryButton(
                    text: 'حفظ التغييرات',
                    onPressed: isLoading ? null : _saveChanges,
                    isLoading: isLoading,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    await context.read<ProfileCubit>().updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }
}
