import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class ConstructionReportsUploader extends StatefulWidget {
  final String projectId;
  final Function(List<Map<String, dynamic>> reports) onReportsSelected;

  const ConstructionReportsUploader({
    super.key,
    required this.projectId,
    required this.onReportsSelected,
  });

  @override
  State<ConstructionReportsUploader> createState() => _ConstructionReportsUploaderState();
}

class _ConstructionReportsUploaderState extends State<ConstructionReportsUploader> {
  final List<Map<String, dynamic>> _reports = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'التقارير',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Dimensions.spaceM),
        
        // Engineering Report
        _buildReportPicker(
          label: 'تقرير هندسي',
          type: 'engineering',
          icon: Icons.engineering,
          color: Colors.blue,
        ),
        const SizedBox(height: Dimensions.spaceM),
        
        // Financial Report
        _buildReportPicker(
          label: 'تقرير مالي',
          type: 'financial',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        const SizedBox(height: Dimensions.spaceM),
        
        // Supervision Report
        _buildReportPicker(
          label: 'تقرير إشراف',
          type: 'supervision',
          icon: Icons.supervisor_account,
          color: Colors.orange,
        ),
        
        // List of selected reports
        if (_reports.isNotEmpty) ...[
          const SizedBox(height: Dimensions.spaceL),
          const Text(
            'التقارير المحددة:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceS),
          ..._reports.map((report) => _buildReportChip(report)),
        ],
      ],
    );
  }

  Widget _buildReportPicker({
    required String label,
    required String type,
    required IconData icon,
    required Color color,
  }) {
    final hasReport = _reports.any((r) => r['type'] == type);
    
    return OutlinedButton.icon(
      icon: Icon(icon, color: hasReport ? color : Colors.grey),
      label: Text(
        label,
        style: TextStyle(color: hasReport ? color : Colors.grey),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: hasReport ? color : Colors.grey.shade300,
          width: 2,
        ),
        backgroundColor: hasReport ? color.withOpacity(0.05) : null,
      ),
      onPressed: () => _pickReport(type),
    );
  }

  Widget _buildReportChip(Map<String, dynamic> report) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: Icon(_getReportIcon(report['type']), size: 16),
        label: Text(
          report['file_name'] ?? 'Report',
          overflow: TextOverflow.ellipsis,
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() {
            _reports.removeWhere((r) => r['type'] == report['type']);
            widget.onReportsSelected(_reports);
          });
        },
      ),
    );
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'engineering':
        return Icons.engineering;
      case 'financial':
        return Icons.attach_money;
      case 'supervision':
        return Icons.supervisor_account;
      default:
        return Icons.description;
    }
  }

  Future<void> _pickReport(String reportType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          // Remove existing report of same type
          _reports.removeWhere((r) => r['type'] == reportType);
          
          // Add new report
          _reports.add({
            'type': reportType,
            'file_name': file.name,
            'file_path': file.path,
            'file_size': file.size,
          });
          
          widget.onReportsSelected(_reports);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم اختيار ${file.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل اختيار الملف')),
        );
      }
    }
  }
}
