import 'package:flutter/material.dart';
import 'package:mmm/core/constants/dimensions.dart';

class SystemSettingsTab extends StatelessWidget {
  const SystemSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      children: [
        _buildSectionHeader(context, 'General Settings'),
        SwitchListTile(
          title: const Text('Enable Maintenance Mode'),
          value: false,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text('Allow New Registrations'),
          value: true,
          onChanged: (val) {},
        ),
        
        const Divider(),
        _buildSectionHeader(context, 'Notification Settings'),
        SwitchListTile(
          title: const Text('Email Notifications'),
          value: true,
          onChanged: (val) {},
        ),
        
        const Divider(),
        _buildSectionHeader(context, 'Backup & Data'),
        ListTile(
          title: const Text('Export All Data'),
          subtitle: const Text('Download full database backup'),
          trailing: IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
