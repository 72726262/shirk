import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/edit_client_screen.dart';

class ClientDetailScreen extends StatelessWidget {
  final UserModel client;

  const ClientDetailScreen({super.key, required this.client});

  Color _getKycStatusColor(String? kycStatus) {
    switch (kycStatus) {
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

  String _getKycStatusText(String? kycStatus) {
    switch (kycStatus) {
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف العميل "${client.fullName}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جاري حذف العميل...')),
              );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العميل'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.spaceXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: Text(
                      client.fullName.toString().isNotEmpty
                          ? client.fullName.toString()[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Text(
                    client.fullName.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceL,
                      vertical: Dimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: _getKycStatusColor(client.kycStatus.toString()),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Text(
                      _getKycStatusText(client.kycStatus.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Info
                  _buildSectionTitle('معلومات الاتصال'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.email,
                      'البريد الإلكتروني',
                      client.email,
                    ),
                    _buildInfoRow(
                      Icons.phone,
                      'رقم الهاتف',
                      client.phone ?? 'غير متوفر',
                    ),
                  ]),

                  const SizedBox(height: Dimensions.spaceXL),

                  // KYC Info
                  _buildSectionTitle('معلومات التوثيق'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.verified_user,
                      'حالة التوثيق',
                      _getKycStatusText(client.kycStatus.toString()),
                    ),
                    _buildInfoRow(
                      Icons.badge,
                      'رقم الهوية',
                      client.nationalId ?? 'غير متوفر',
                    ),
                  ]),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Payments Section
                  _buildSectionTitle('المدفوعات'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildPaymentsSection(),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Admin Actions
                  _buildSectionTitle('إجراءات المشرف'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildAdminActions(context),

                  const SizedBox(height: Dimensions.spaceXXL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    // TODO: Fetch actual payments from Cubit
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.payment, size: 48, color: AppColors.gray400),
            SizedBox(height: Dimensions.spaceM),
            Text(
              'سيتم عرض المدفوعات هنا',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      children: [
        // Edit Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ClientManagementCubit>(),
                    child: EditClientScreen(client: client),
                  ),
                ),
              );
              // Refresh list if changes were saved
              if (result == true && context.mounted) {
                context.read<ClientManagementCubit>().loadClients();
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('تعديل بيانات العميل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.spaceM),

        // Delete Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete),
            label: const Text('حذف العميل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
