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
          _buildSectionHeader('الإشعارات'),
          _buildCard([
            SwitchListTile(
              title: const Text('تفعيل الإشعارات'),
              subtitle: const Text('تلقي إشعارات حول التحديثات المهمة'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات البريد الإلكتروني'),
              value: _emailNotifications,
              onChanged: _notificationsEnabled ? (value) => setState(() => _emailNotifications = value) : null,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('إشعارات SMS'),
              value: _smsNotifications,
              onChanged: _notificationsEnabled ? (value) => setState(() => _smsNotifications = value) : null,
            ),
          ]),
          const SizedBox(height: Dimensions.spaceXL),

          // Language Section
          _buildSectionHeader('اللغة'),
          _buildCard([
            RadioListTile<String>(
              title: const Text('العربية'),
              value: 'ar',
              groupValue: _language,
              onChanged: (value) => setState(() => _language = value!),
            ),
            const Divider(),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) => setState(() => _language = value!),
            ),
          ]),
          const SizedBox(height: Dimensions.spaceXL),

          // Theme Section
          _buildSectionHeader('المظهر'),
          _buildCard([
            RadioListTile<String>(
              title: const Text('فاتح'),
              value: 'light',
              groupValue: _theme,
              onChanged: (value) => setState(() => _theme = value!),
            ),
            const Divider(),
            RadioListTile<String>(
              title: const Text('داكن'),
              value: 'dark',
              groupValue: _theme,
              onChanged: (value) => setState(() => _theme = value!),
            ),
          ]),
          const SizedBox(height: Dimensions.spaceXL),

          // Other Settings
          _buildSectionHeader('أخرى'),
          _buildCard([
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('تغيير كلمة المرور'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('حذف الحساب'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
