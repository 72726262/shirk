import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/contract_model.dart';
import 'package:intl/intl.dart';

class ContractDetailScreen extends StatelessWidget {
  final ContractModel contract;

  const ContractDetailScreen({super.key, required this.contract});

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'executed':
        return AppColors.info;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'ساري';
      case 'pending':
        return 'معلق';
      case 'executed':
        return 'منفذ';
      case 'expired':
        return 'منتهي';
      default:
        return 'غير معروف';
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف العقد "${contract.title ?? 'هذا العقد'}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
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
                const SnackBar(content: Text('جاري حذف العقد...')),
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
        title: const Text('تفاصيل العقد'),
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
                    _getStatusColor(contract.status.toString()),
                    _getStatusColor(
                      contract.status.toString(),
                    ).withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.white),
                  const SizedBox(height: Dimensions.spaceM),
                  Text(
                    contract.title ?? 'عقد #${contract.id}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceL,
                      vertical: Dimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Text(
                      _getStatusText(contract.status.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                  // Contract Info
                  _buildSectionTitle('معلومات العقد'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow(
                      'رقم العقد',
                      contract.id?.toString() ?? 'N/A',
                    ),
                    if (contract.createdAt != null)
                      _buildInfoRow(
                        'تاريخ البدء',
                        DateFormat('yyyy-MM-dd').format(contract.createdAt!),
                      ),
                    if (contract.expiryDate != null)
                      _buildInfoRow(
                        'تاريخ الانتهاء',
                        DateFormat('yyyy-MM-dd').format(contract.expiryDate!),
                      ),
                  ]),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Client Info
                  _buildSectionTitle('معلومات العميل'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow(
                      'معرف العميل',
                      contract.userId.substring(0, 8) + '...',
                    ),
                  ]),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Project Info
                  if (contract.projectId != null) ...[
                    _buildSectionTitle('معلومات المشروع'),
                    const SizedBox(height: Dimensions.spaceM),
                    _buildInfoCard([
                      _buildInfoRow(
                        'معرف المشروع',
                        contract.projectId!.substring(0, 8) + '...',
                      ),
                    ]),
                    const SizedBox(height: Dimensions.spaceXL),
                  ],

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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    // TODO: Fetch actual payments
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('صفحة التعديل قيد التطوير')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('تعديل العقد'),
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
            label: const Text('حذف العقد'),
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
