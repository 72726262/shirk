import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:intl/intl.dart';

class PaymentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> payment;

  const PaymentDetailsDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceXL),
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل الدفعة',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: Dimensions.spaceM),
            
            _buildInfoRow('رقم الدفعة:', payment['id'] ?? '-'),
            _buildInfoRow('المبلغ:', '${payment['amount'] ?? 0} ريال'),
            _buildInfoRow('الحالة:', _getStatusText(payment['status'])),
            _buildInfoRow('النوع:', _getTypeText(payment['type'])),
            _buildInfoRow('التاريخ:', _formatDate(payment['created_at'])),
            _buildInfoRow('المشروع:', payment['project_name'] ?? '-'),
            _buildInfoRow('الوحدة:', payment['unit_number']?.toString() ?? '-'),
            _buildInfoRow('العميل:', payment['client_name'] ?? '-'),
            
            if (payment['description'] != null) ...[
              const SizedBox(height: Dimensions.spaceM),
              const Text('الوصف:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(payment['description']),
            ],
            
            const SizedBox(height: Dimensions.spaceXL),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('تنزيل الإيصال'),
                    onPressed: () {
                      // TODO: Download receipt as PDF
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جار تنزيل الإيصال...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: Dimensions.spaceM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'pending':
        return 'قيد الانتظار';
      case 'overdue':
        return 'متأخر';
      case 'cancelled':
        return 'ملغي';
      default:
        return '-';
    }
  }

  String _getTypeText(String? type) {
    switch (type) {
      case 'down_payment':
        return 'دفعة مقدمة';
      case 'installment':
        return 'قسط';
      case 'final_payment':
        return 'دفعة نهائية';
      default:
        return '-';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '-';
    }
  }
}
