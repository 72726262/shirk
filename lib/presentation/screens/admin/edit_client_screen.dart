import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:mmm/presentation/widgets/common/primary_button.dart';

class EditClientScreen extends StatefulWidget {
  final UserModel client;

  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalIdController;

  bool _isLoading = false;

  File? _newAvatarFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.client.fullName);
    // ... rest of init
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    _nationalIdController = TextEditingController(
      text: widget.client.nationalId,
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newAvatarFile = File(image.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<ClientManagementCubit>().updateClient(
        userId: widget.client.id,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        nationalId: _nationalIdController.text,
        avatarPath: _newAvatarFile?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ التعديلات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل بيانات العميل'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          children: [
            // Avatar section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _newAvatarFile != null
                        ? FileImage(_newAvatarFile!) as ImageProvider
                        : (widget.client.avatarUrl != null
                              ? NetworkImage(widget.client.avatarUrl!)
                              : null),
                    child:
                        (_newAvatarFile == null &&
                            widget.client.avatarUrl == null)
                        ? Text(
                            widget.client.fullName?.isNotEmpty ?? false
                                ? widget.client.fullName![0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.spaceXXL),

            // Full Name
            CustomTextField(
              controller: _fullNameController,
              label: 'الاسم الكامل',
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الاسم الكامل';
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Email (Read Only)
            CustomTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              prefixIcon: Icons.email,
              enabled: false,
              hint: 'لا يمكن تعديل البريد الإلكتروني',
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Phone
            CustomTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الهاتف';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
                }
                if (value.length < 9) {
                  return 'رقم الهاتف قصير جداً';
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spaceL),

            // National ID
            CustomTextField(
              controller: _nationalIdController,
              label: 'رقم الهوية الوطنية',
              prefixIcon: Icons.badge,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length != 10) {
                    return 'رقم الهوية يجب أن يتكون من 10 أرقام';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spaceXXL),

            // KYC Status Display
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حالة التوثيق (KYC)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Row(
                    children: [
                      Icon(
                        _getKycIcon(widget.client.kycStatus.toString()),
                        color: _getKycColor(widget.client.kycStatus.toString()),
                      ),
                      const SizedBox(width: Dimensions.spaceM),
                      Text(
                        _getKycText(widget.client.kycStatus.toString()),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getKycColor(
                            widget.client.kycStatus.toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  const Text(
                    'لتغيير حالة التوثيق، استخدم صفحة تفاصيل العميل',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.spaceXXL),

            // Save Button
            PrimaryButton(
              text: 'حفظ التعديلات',
              onPressed: _isLoading ? null : _saveChanges,
              isLoading: _isLoading,
            ),
            const SizedBox(height: Dimensions.spaceM),

            // Cancel Button
            OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.gray300),
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.spaceM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
              ),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getKycColor(String? status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getKycText(String? status) {
    switch (status) {
      case 'verified':
        return 'موثق';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير مكتمل';
    }
  }

  IconData _getKycIcon(String? status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
