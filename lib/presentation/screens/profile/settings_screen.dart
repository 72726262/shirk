import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  String _language = 'ar';
  String _theme = 'light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.spaceXXL),
        children: [
          // Notifications Section
          _buildSectionHeader('الإشعارات', Icons.notifications),
          _buildCard(
            children: [
              _buildSwitchTile(
                title: 'تفعيل الإشعارات',
                subtitle: 'تلقي جميع الإشعارات',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'إشعارات البريد الإلكتروني',
                subtitle: 'تلقي الإشعارات عبر البريد',
                value: _emailNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _emailNotifications = value);
                      }
                    : null,
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'إشعارات الرسائل النصية',
                subtitle: 'تلقي الإشعارات عبر SMS',
                value: _smsNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _smsNotifications = value);
                      }
                    : null,
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'الإشعارات الفورية',
                subtitle: 'تلقي الإشعارات المباشرة',
                value: _pushNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() => _pushNotifications = value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // Appearance Section
          _buildSectionHeader('المظهر', Icons.palette),
          _buildCard(
            children: [
              _buildRadioTile(
                title: 'اللغة',
                options: const {
                  'ar': 'العربية',
                  'en': 'English',
                },
                value: _language,
                onChanged: (value) {
                  setState(() => _language = value!);
                },
              ),
              const Divider(height: 1),
              _buildRadioTile(
                title: 'المظهر',
                options: const {
                  'light': 'فاتح',
                  'dark': 'داكن',
                  'system': 'تلقائي',
                },
                value: _theme,
                onChanged: (value) {
                  setState(() => _theme = value!);
                },
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // Security Section
          _buildSectionHeader('الأمان', Icons.security),
          _buildCard(
            children: [
              _buildActionTile(
                title: 'تغيير كلمة المرور',
                icon: Icons.lock,
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'المصادقة الثنائية',
                icon: Icons.security,
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'الأجهزة المتصلة',
                icon: Icons.devices,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // Privacy Section
          _buildSectionHeader('الخصوصية', Icons.privacy_tip),
          _buildCard(
            children: [
              _buildActionTile(
                title: 'سياسة الخصوصية',
                icon: Icons.description,
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'الشروط والأحكام',
                icon: Icons.gavel,
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildActionTile(
                title: 'حذف الحساب',
                icon: Icons.delete_forever,
                iconColor: AppColors.error,
                titleColor: AppColors.error,
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceL),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: Dimensions.spaceM),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  Widget _buildRadioTile({
    required String title,
    required Map<String, String> options,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return ExpansionTile(
      title: Text(title),
      subtitle: Text(
        options[value] ?? '',
        style: TextStyle(fontSize: 12, color: AppColors.primary),
      ),
      children: options.entries.map((entry) {
        return RadioListTile<String>(
          title: Text(entry.value),
          value: entry.key,
          groupValue: value,
          onChanged: (val) {
            onChanged(val);
          },
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.gray500),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: Icon(
        Icons.arrow_back_ios,
        size: 16,
        color: AppColors.gray400,
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete account logic
              Navigator.pop(context);
            },
            child: const Text(
              'حذف الحساب',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
