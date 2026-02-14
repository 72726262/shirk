import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_cubit.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:intl/intl.dart';
import 'package:mmm/presentation/screens/documents/upload_document_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../../../cubits/admin/documents_management_state.dart';

class DocumentsManagementTab extends StatefulWidget {
  const DocumentsManagementTab({super.key});

  @override
  State<DocumentsManagementTab> createState() => _DocumentsManagementTabState();
}

class _DocumentsManagementTabState extends State<DocumentsManagementTab> {
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    context.read<DocumentsManagementCubit>().loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadDocumentScreen(),
            ),
          );
        },
        label: const Text('رفع مستند'),
        icon: const Icon(Icons.upload_file),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child:
                BlocConsumer<
                  DocumentsManagementCubit,
                  DocumentsManagementState
                >(
                  listener: (context, state) {
                    if (state is DocumentsManagementError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else if (state is DocumentUploadedSuccessfully) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم رفع المستند بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is DocumentsManagementLoading) {
                      return _buildSkeletonLoader();
                    }

                    if (state is DocumentsManagementLoaded) {
                      return _buildDocumentsGrid(state.documents);
                    }

                    return const Center(child: Text('لا توجد مستندات'));
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Dimensions.spaceM,
              children: [
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = null);
                      context.read<DocumentsManagementCubit>().loadDocuments();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('عقود'),
                  selected: _selectedType == 'contract',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = 'contract');
                      context.read<DocumentsManagementCubit>().loadDocuments(
                        type: 'contract',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('هوية'),
                  selected: _selectedType == 'kyc',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = 'kyc');
                      context.read<DocumentsManagementCubit>().loadDocuments(
                        type: 'kyc',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('إيصالات'),
                  selected: _selectedType == 'receipt',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = 'receipt');
                      context.read<DocumentsManagementCubit>().loadDocuments(
                        type: 'receipt',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('أخرى'),
                  selected: _selectedType == 'other',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = 'other');
                      context.read<DocumentsManagementCubit>().loadDocuments(
                        type: 'other',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsGrid(List<DocumentModel> documents) {
    if (documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.textSecondary),
            SizedBox(height: Dimensions.spaceM),
            Text('لا توجد مستندات'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: Dimensions.spaceL,
        mainAxisSpacing: Dimensions.spaceL,
        childAspectRatio: 0.8,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _viewDocument(document),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getDocumentIcon(document.type),
                    size: 40,
                    color: AppColors.primary,
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: Dimensions.spaceS),
                            Text('عرض'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: AppColors.primary),
                            SizedBox(width: Dimensions.spaceS),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 18),
                            SizedBox(width: Dimensions.spaceS),
                            Text('تحميل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: Dimensions.spaceS),
                            Text(
                              'حذف',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _viewDocument(document);
                      } else if (value == 'edit') {
                        _editDocument(document);
                      } else if (value == 'download') {
                        context
                            .read<DocumentsManagementCubit>()
                            .downloadDocument(document.id);
                      } else if (value == 'delete') {
                        _deleteDocument(document.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      _getDocumentTypeLabel(document.type),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yyyy').format(document.uploadedAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.contract:
        return Icons.description;
      case DocumentType.kyc:
        return Icons.badge;
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.other:
        return Icons.insert_drive_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.contract:
        return 'عقد';
      case DocumentType.kyc:
        return 'هوية';
      case DocumentType.receipt:
        return 'إيصال';
      case DocumentType.other:
        return 'أخرى';
      default:
        return 'غير محدد';
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفع مستند'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('النوع: ${_getDocumentTypeLabel(document.type)}'),
            const SizedBox(height: Dimensions.spaceS),
            if (document.description != null) ...[
              Text('الوصف: ${document.description}'),
              const SizedBox(height: Dimensions.spaceS),
            ],
            Text(
              'تاريخ الرفع: ${DateFormat('dd/MM/yyyy').format(document.uploadedAt)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<DocumentsManagementCubit>().downloadDocument(
                document.id,
              );
              Navigator.pop(context);
            },
            child: const Text('تحميل'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _editDocument(DocumentModel document) {
    // Navigate to edit document screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadDocumentScreen(),
      ),
    );
  }

  void _deleteDocument(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المستند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentsManagementCubit>().deleteDocument(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Dimensions.spaceM,
        mainAxisSpacing: Dimensions.spaceM,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.gray200,
          highlightColor: AppColors.gray100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.radiusL),
                        topRight: Radius.circular(Dimensions.radiusL),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.spaceM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: Dimensions.spaceS),
                        Container(
                          height: 12,
                          width: 80,
                          color: AppColors.gray300,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
