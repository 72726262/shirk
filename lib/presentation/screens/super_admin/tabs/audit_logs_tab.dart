import 'package:flutter/material.dart';
import 'package:mmm/core/constants/dimensions.dart';

class AuditLogsTab extends StatelessWidget {
  const AuditLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for Audit Logs
    // In real implementation, this would fetch from 'audit_logs' table
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceS),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text('Action #${1000 + index}'),
            subtitle: Text('Admin updated Project X • ${DateTime.now().subtract(Duration(hours: index)).toString().substring(0, 16)}'),
            trailing: const Text('Details'),
          ),
        );
      },
    );
  }
}
