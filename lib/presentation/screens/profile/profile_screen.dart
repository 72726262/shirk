import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  final UserModel _user = UserModel(
    id: '1',
    email: 'user@example.com',
    fullName: 'محمد أحمد',
    phone: '+966500000000',
    nationalId: '1234567890',
    role: UserRole.client,
    kycStatus: KycStatus.approved,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
    updatedAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: Dimensions.spaceXXL),
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.white,
                          child: Text(
                            (_user.fullName ?? '?')[0],
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      Text(
                        _user.fullName.toString(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceL,
                          vertical: Dimensions.spaceS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 16,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: Dimensions.spaceS),
                            Text(
                              _user.kycStatus.displayName,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.spaceXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information Card
                  _buildCard(
                    title: 'المعلومات الشخصية',
                    icon: Icons.person,
                    children: [
                      _buildInfoRow(
                        label: 'البريد الإلكتروني',
                        value: _user.email,
                        icon: Icons.email,
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildInfoRow(
                        label: 'رقم الجوال',
                        value: _user.phone ?? 'غير محدد',
                        icon: Icons.phone,
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildInfoRow(
                        label: 'رقم الهوية',
                        value: _user.nationalId ?? 'غير محدد',
                        icon: Icons.badge,
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Account Settings Card
                  _buildCard(
                    title: 'إعدادات الحساب',
                    icon: Icons.settings,
                    children: [
                      _buildActionRow(
                        label: 'تعديل الملف الشخصي',
                        icon: Icons.edit,
                        onTap: () {
                          Navigator.pushNamed(context, '/profile/edit');
                        },
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildActionRow(
                        label: 'تغيير كلمة المرور',
                        icon: Icons.lock,
                        onTap: () {},
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildActionRow(
                        label: 'الإعدادات',
                        icon: Icons.tune,
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // About Card
                  _buildCard(
                    title: 'عن التطبيق',
                    icon: Icons.info,
                    children: [
                      _buildActionRow(
                        label: 'الشروط والأحكام',
                        icon: Icons.description,
                        onTap: () {},
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildActionRow(
                        label: 'سياسة الخصوصية',
                        icon: Icons.privacy_tip,
                        onTap: () {},
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildActionRow(
                        label: 'اتصل بنا',
                        icon: Icons.support_agent,
                        onTap: () {},
                      ),
                      const Divider(height: Dimensions.spaceXXL),
                      _buildInfoRow(
                        label: 'الإصدار',
                        value: '1.0.0',
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Logout Button
                  PrimaryButton(
                    text: 'تسجيل الخروج',
                    onPressed: _logout,
                    leadingIcon: Icons.logout,
                    backgroundColor: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: Dimensions.spaceM),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceXL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gray500),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Dimensions.spaceXS),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray500),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Icon(Icons.arrow_back_ios, size: 16, color: AppColors.gray400),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
