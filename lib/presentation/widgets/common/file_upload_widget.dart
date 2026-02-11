import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'dart:io';

class FileUploadWidget extends StatefulWidget {
  final Function(List<String>) onFilesSelected;
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final String buttonText;
  final IconData icon;
  final int? maxFiles;

  const FileUploadWidget({
    super.key,
    required this.onFilesSelected,
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'png'],
    this.allowMultiple = false,
    this.buttonText = 'اختيار ملف',
    this.icon = Icons.upload_file,
    this.maxFiles,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  List<String> _selectedFiles = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Button
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _pickFiles,
          icon: Icon(widget.icon),
          label: Text(widget.buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.spaceL,
              vertical: Dimensions.spaceM,
            ),
          ),
        ),

        // Selected Files List
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: Dimensions.spaceM),
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الملفات المختارة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceS),
                ..._selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filePath = entry.value;
                  return _buildFileItem(filePath, index);
                }),
              ],
            ),
          ),
        ],

        // Allowed Extensions Info
        const SizedBox(height: Dimensions.spaceS),
        Text(
          'الأنواع المسموحة: ${widget.allowedExtensions.join(', ').toUpperCase()}',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(String filePath, int index) {
    final fileName = filePath.split('/').last;
    final fileSize = _getFileSize(filePath);

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceS),
      padding: const EdgeInsets.all(Dimensions.spaceS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(fileName),
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: Dimensions.spaceS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileSize,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      setState(() => _isUploading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      if (result != null) {
        final newFiles = result.paths.whereType<String>().toList();

        // Check max files limit
        if (widget.maxFiles != null && 
            _selectedFiles.length + newFiles.length > widget.maxFiles!) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('الحد الأقصى ${widget.maxFiles} ملفات'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isUploading = false);
          return;
        }

        setState(() {
          if (widget.allowMultiple) {
            _selectedFiles.addAll(newFiles);
          } else {
            _selectedFiles = newFiles;
          }
        });

        widget.onFilesSelected(_selectedFiles);
      }

      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار الملفات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected(_selectedFiles);
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes بايت';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
    } catch (e) {
      return 'غير معروف';
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mpeg':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}
