import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/clients_management_cubit.dart';

class ClientTable extends StatelessWidget {
  final List<UserModel> clients;

  const ClientTable({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withOpacity(0.05),
          ),
          columns: const [
            DataColumn(label: Text('العميل')),
            DataColumn(label: Text('البريد الإلكتروني')),
            DataColumn(label: Text('رقم الهاتف')),
            DataColumn(label: Text('حالة التوثيق (KYC)')),
            DataColumn(label: Text('الإجراءات')),
          ],
          rows: clients.map((client) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: client.avatarUrl != null
                            ? NetworkImage(client.avatarUrl!)
                            : null,
                        child: client.avatarUrl == null
                            ? Text(
                                (client.fullName ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(client.fullName ?? '-'),
                    ],
                  ),
                ),
                DataCell(Text(client.email)),
                DataCell(Text(client.phone ?? '-')),
                DataCell(_buildKYCStatusChip(client.kycStatus.name)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        tooltip: 'التفاصيل',
                        onPressed: () {
                          _showClientDetails(context, client);
                        },
                      ),
                      if (client.kycStatus == KYCStatus.pending) ...[
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: AppColors.success),
                          tooltip: 'موافقة',
                          onPressed: () {
                            context.read<ClientsManagementCubit>().approveKYC(client.id);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: AppColors.error),
                          tooltip: 'رفض',
                          onPressed: () {
                            _showRejectDialog(context, client);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildKYCStatusChip(String? status) {
    Color color;
    String label;

    switch (status) {
      case 'verified':
      case 'approved':
        color = AppColors.success;
        label = 'موثق';
        break;
      case 'pending':
        color = AppColors.warning;
        label = 'قيد المراجعة';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'مرفوض';
        break;
      default:
        color = Colors.grey;
        label = 'غير مقدم';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showClientDetails(BuildContext context, UserModel client) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تفاصيل العميل', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              // Add more details here
              ListTile(leading: Icon(Icons.person), title: Text(client.fullName ?? '-')),
              ListTile(leading: Icon(Icons.email), title: Text(client.email)),
              ListTile(leading: Icon(Icons.phone), title: Text(client.phone ?? '-')),
               if (client.kycStatus == KYCStatus.pending)
                 ElevatedButton(
                   onPressed: () {
                     // Show ID preview if needed
                   }, 
                   child: Text('عرض مستندات التوثيق')
                 ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, UserModel client) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض التوثيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى ذكر سبب الرفض:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ClientsManagementCubit>().rejectKYC(
                client.id,
                reasonController.text,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}
