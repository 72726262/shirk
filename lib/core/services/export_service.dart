import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  /// Export payments data to PDF
  static Future<String> exportPaymentsToPDF(
    List<Map<String, dynamic>> payments,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'تقرير المدفوعات',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'التاريخ: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'المبلغ', 'الحالة', 'النوع', 'العميل', 'التاريخ'],
            data: payments.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final payment = entry.value;
              return [
                index.toString(),
                '${payment['amount'] ?? 0} ريال',
                _getStatusTextAr(payment['status']),
                _getTypeTextAr(payment['type']),
                payment['client_name'] ?? '-',
                _formatDate(payment['created_at']),
              ];
            }).toList(),
            cellAlignment: pw.Alignment.centerRight,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellPadding: const pw.EdgeInsets.all(5),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'إجمالي المدفوعات: ${payments.length}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'المجموع: ${_calculateTotal(payments)} ريال',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/payments_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// Export payments data to CSV
  static Future<String> exportPaymentsToCSV(
    List<Map<String, dynamic>> payments,
  ) async {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('رقم,المبلغ,الحالة,النوع,العميل,المشروع,التاريخ');

    // Data rows
    for (var i = 0; i < payments.length; i++) {
      final payment = payments[i];
      buffer.writeln(
        '${i + 1},'
        '"${payment['amount'] ?? 0}",'
        '"${_getStatusTextAr(payment['status'])}",'
        '"${_getTypeTextAr(payment['type'])}",'
        '"${payment['client_name'] ?? '-'}",'
        '"${payment['project_name'] ?? '-'}",'
        '"${_formatDate(payment['created_at'])}"',
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/payments_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  static String _getStatusTextAr(String? status) {
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

  static String _getTypeTextAr(String? type) {
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

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '-';
    }
  }

  static double _calculateTotal(List<Map<String, dynamic>> payments) {
    return payments.fold(0.0, (sum, payment) {
      final amount = payment['amount'];
      if (amount is num) {
        return sum + amount.toDouble();
      }
      return sum;
    });
  }
}
