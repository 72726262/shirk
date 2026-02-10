import 'package:flutter/material.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:intl/intl.dart';

class ClientActivityLogsDialog extends StatelessWidget {
  final String clientId;
  final String clientName;

  const ClientActivityLogsDialog({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceXL),
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سجل النشاطات',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clientName,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: Dimensions.spaceM),
            
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchActivityLogs(clientId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }

                  final activities = snapshot.data ?? [];
                  
                  if (activities.isEmpty) {
                    return const Center(
                      child: Text('لا توجد نشاطات مسجلة'),
                    );
                  }

                  return ListView.separated(
                    itemCount: activities.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      return _buildActivityTile(activity);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final icon = _getActivityIcon(activity['type']);
    final color = _getActivityColor(activity['type']);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity['description'] ?? 'نشاط',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity['details'] != null)
            Text(activity['details']),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(activity['created_at']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      isThreeLine: activity['details'] != null,
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'login':
        return Icons.login;
      case 'project_view':
        return Icons.visibility;
      case 'payment':
        return Icons.payment;
      case 'document_upload':
        return Icons.upload_file;
      case 'profile_update':
        return Icons.person;
      case 'contract_sign':
        return Icons.draw;
      default:
        return Icons.event;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'login':
        return Colors.blue;
      case 'project_view':
        return Colors.purple;
      case 'payment':
        return Colors.green;
      case 'document_upload':
        return Colors.orange;
      case 'profile_update':
        return Colors.indigo;
      case 'contract_sign':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
    } catch (e) {
      return '-';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActivityLogs(String clientId) async {
    // TODO: Fetch from Supabase activity_logs table
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data for now
    return [
      {
        'type': 'login',
        'description': 'تسجيل دخول',
        'details': 'تسجيل دخول من عنوان IP: 192.168.1.1',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'type': 'project_view',
        'description': 'عرض مشروع',
        'details': 'عرض تفاصيل مشروع الرياض الخضراء',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'type': 'payment',
        'description': 'دفع قسط',
        'details': 'دفع قسط رقم 3 بمبلغ 50,000 ريال',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'type': 'document_upload',
        'description': 'رفع مستند',
        'details': 'رفع صورة الهوية الوطنية',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
  }
}
