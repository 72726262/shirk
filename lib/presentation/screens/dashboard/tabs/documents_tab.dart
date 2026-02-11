import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/services/document_service.dart';
import 'package:intl/intl.dart';

class DocumentsTab extends StatefulWidget {
  final String userId;

  const DocumentsTab({super.key, required this.userId});

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _error;
  DocumentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final documents = await _documentService.getUserDocuments(
        userId: widget.userId,
        type: _selectedType,
      );
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مستنداتي'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', null),
                  const SizedBox(width: Dimensions.spaceS),
                  ...DocumentType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(left: Dimensions.spaceS),
                        child: _buildFilterChip(type.displayName, type),
                      )),
                ],
              ),
            ),
          ),
          // Documents List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DocumentType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
        _loadDocuments();
      },
      backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Dimensions.spaceM),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: _loadDocuments,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: Dimensions.spaceM),
            Text(
              _selectedType != null
                  ? 'لا توجد مستندات من نوع ${_selectedType!.displayName}'
                  : 'لا توجد مستندات',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: Dimensions.screenPadding,
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          return _buildDocumentCard(_documents[index]);
        },
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(Dimensions.spaceM),
        leading: CircleAvatar(
          backgroundColor: _getDocumentTypeColor(document.type).withOpacity(0.1),
          child: Icon(
            _getDocumentTypeIcon(document.type),
            color: _getDocumentTypeColor(document.type),
          ),
        ),
        title: Text(
          document.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.spaceXS),
            Text(document.type.displayName),
            const SizedBox(height: Dimensions.spaceXS),
            Text(
              'تاريخ الرفع: ${DateFormat('dd/MM/yyyy').format(document.createdAt)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (document.requiresSignature) ...[
              const SizedBox(height: Dimensions.spaceXS),
              _buildSignatureStatus(document.isSigned),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: Dimensions.spaceS),
                  Text('تحميل'),
                ],
              ),
            ),
            if (document.requiresSignature && !document.isSigned)
              const PopupMenuItem(
                value: 'sign',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: Dimensions.spaceS),
                    Text('توقيع'),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            if (value == 'download') {
              _downloadDocument(document);
            } else if (value == 'sign') {
              _signDocument(document);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSignatureStatus(bool isSigned) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: isSigned ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSigned ? Icons.check_circle : Icons.pending,
            size: 14,
            color: isSigned ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: Dimensions.spaceXS),
          Text(
            isSigned ? 'موقع' : 'بانتظار التوقيع',
            style: TextStyle(
              fontSize: 11,
              color: isSigned ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.contract:
        return AppColors.primary;
      case DocumentType.invoice:
        return AppColors.warning;
      case DocumentType.receipt:
        return AppColors.success;
      case DocumentType.certificate:
        return AppColors.info;
      case DocumentType.kyc:
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.invoice:
        return Icons.receipt_long;
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.certificate:
        return Icons.workspace_premium;
      case DocumentType.kyc:
        return Icons.badge;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _downloadDocument(DocumentModel document) async {
    try {
      final url = await _documentService.getDocumentDownloadUrl(document.id);
      // TODO: Implement actual download logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رابط التحميل: $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التحميل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _signDocument(DocumentModel document) {
    // TODO: Implement signature workflow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إضافة ميزة التوقيع قريباً')),
    );
  }
}
