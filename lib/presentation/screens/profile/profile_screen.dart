import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/widgets/common/image_picker_widget.dart';
import 'package:mmm/presentation/widgets/inputs/primary_text_field.dart';
import 'package:mmm/presentation/widgets/buttons/primary_button.dart';
import 'package:mmm/data/services/storage_service.dart';
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:mmm/data/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final AuthRepository _authRepository = AuthRepository();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedAvatarPath;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      setState(() {
        _nameController.text = authState.user.fullName ?? '';
        _emailController.text = authState.user.email ?? '';
        _phoneController.text = authState.user.phone ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
                if (!_isEditMode) {
                  _loadUserData(); // Reset data if canceling edit
                }
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return const Center(child: Text('الرجاء تسجيل الدخول'));
          }

          return SingleChildScrollView(
            padding: Dimensions.screenPadding,
            child: Column(
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: state.user.avatarUrl != null
                              ? Image.network(
                                  state.user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAvatar();
                                  },
                                )
                              : _buildDefaultAvatar(),
                        ),
                      ),
                      if (_isEditMode)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _showAvatarPicker,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),

                // User Info
                _buildInfoCard(
                  title: 'معلومات الحساب',
                  children: [
                    PrimaryTextField(
                      controller: _nameController,
                      label: 'الاسم',
                      enabled: _isEditMode,
                      prefixIcon: Icons.person,
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    PrimaryTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      enabled: false, // Email can't be changed
                      prefixIcon: Icons.email,
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    PrimaryTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      enabled: _isEditMode,
                      prefixIcon: Icons.phone,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Account Details
                _buildInfoCard(
                  title: 'تفاصيل الحساب',
                  children: [
                    _buildInfoRow('نوع الحساب', _getRoleLabel(state.user.role)),
                    const Divider(),
                    _buildInfoRow('حالة التحقق', state.user.kycStatus == KYCStatus.approved ? 'موثق ✓' : 'غير موثق'),
                    const Divider(),
                    _buildInfoRow('تاريخ التسجيل', _formatDate(state.user.createdAt)),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceXL),

                // Save Button (only in edit mode)
                if (_isEditMode)
                  PrimaryButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    text: 'حفظ التغييرات',
                    isLoading: _isLoading,
                  ),
                const SizedBox(height: Dimensions.spaceL),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().signOut();
                  },
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Icon(
        Icons.person,
        size: 60,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Dimensions.spaceM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تحديث الصورة الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              ImagePickerWidget(
                onImageSelected: (path) {
                  if (path.isNotEmpty) {
                    setState(() {
                      _selectedAvatarPath = path;
                    });
                    Navigator.pop(context);
                  }
                },
                height: 200,
                emptyText: 'اختر صورة جديدة',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return;

      String? avatarUrl;

      // Upload avatar if selected
      if (_selectedAvatarPath != null) {
        avatarUrl = await _storageService.uploadAvatar(
          _selectedAvatarPath!,
          authState.user.id,
        );
      }

      // Update profile
      await _authRepository.updateProfile(
        userId: authState.user.id,
        fullName: _nameController.text,
        phone: _phoneController.text,
        avatarPath: avatarUrl,
      );

      // Refresh auth state
      await context.read<AuthCubit>().refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الملف الشخصي بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isEditMode = false;
          _selectedAvatarPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'client':
        return 'عميل';
      case 'admin':
        return 'مدير';
      case 'super_admin':
        return 'مدير عام';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
