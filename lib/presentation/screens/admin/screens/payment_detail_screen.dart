import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:intl/intl.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const PaymentDetailScreen({super.key, required this.transaction});

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'مكتمل';
      case 'pending':
        return 'معلق';
      case 'failed':
        return 'فشل';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] as num? ?? 0;
    final status = transaction['status'] as String?;
    final type = transaction['type'] as String? ?? 'غير محدد';
    final createdAt = transaction['created_at'] as String?;
    final userName = transaction['user_name'] as String? ?? 'غير معروف';
    final userEmail = transaction['user_email'] as String? ?? 'غير معروف';
    final projectName = transaction['project_name'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الدفع'),
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
                    _getStatusColor(status),
                    _getStatusColor(status).withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.payment,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Text(
                    '$amount ر.س',
                    style: const TextStyle(
                      fontSize: 36,
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
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Text(
                      _getStatusText(status),
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
                  // Transaction Info
                  _buildSectionTitle('معلومات المعاملة'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow('رقم المعاملة', transaction['id']?.toString() ?? 'N/A'),
                    _buildInfoRow('النوع', type),
                    if (createdAt != null)
                      _buildInfoRow(
                        'التاريخ',
                        DateFormat('yyyy-MM-dd HH:mm').format(
                          DateTime.parse(createdAt),
                        ),
                      ),
                  ]),

                  const SizedBox(height: Dimensions.spaceXL),

                  // User Info
                  _buildSectionTitle('معلومات العميل'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildInfoCard([
                    _buildInfoRow('الاسم', userName),
                    _buildInfoRow('البريد الإلكتروني', userEmail),
                  ]),

                  if (projectName != null) ...[
                    const SizedBox(height: Dimensions.spaceXL),

                    // Project Info
                    _buildSectionTitle('معلومات المشروع'),
                    const SizedBox(height: Dimensions.spaceM),
                    _buildInfoCard([
                      _buildInfoRow('اسم المشروع', projectName),
                    ]),
                  ],

                  const SizedBox(height: Dimensions.spaceXL),

                  // Contract Details Section
                  _buildSectionTitle('تفاصيل العقد'),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildContractSection(),

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
      child: Column(
        children: children,
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

  Widget _buildContractSection() {
    // TODO: Fetch actual contract details
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.description, size: 48, color: AppColors.gray400),
            SizedBox(height: Dimensions.spaceM),
            Text(
              'سيتم عرض تفاصيل العقد هنا',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
