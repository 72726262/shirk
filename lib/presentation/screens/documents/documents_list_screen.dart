// lib/presentation/screens/documents/documents_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart';

class DocumentsListScreen extends StatelessWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المستندات'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.uploadDocument);
            },
          ),
        ],
      ),
      body: BlocBuilder<DocumentsCubit, DocumentsState>(
        builder: (context, state) {
          if (state is DocumentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: Dimensions.spaceL),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (state is DocumentsLoaded) {
            if (state.documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text('لا توجد مستندات'),
                  ],
                ),
              );
            }

            // Group documents by category
            final groupedDocs = <String, List<DocumentModel>>{};
            for (var doc in state.documents) {
              groupedDocs.putIfAbsent(doc.category, () => []).add(doc);
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<DocumentsCubit>()
                      .loadUserDocuments(authState.user.id);
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: groupedDocs.length,
                itemBuilder: (context, index) {
                  final category = groupedDocs.keys.elementAt(index);
                  final docs = groupedDocs[category]!;
                  return _buildCategorySection(context, category, docs);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<DocumentModel> documents,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
          child: Text(
            _getCategoryDisplayName(category),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...documents.map((doc) => _buildDocumentCard(context, doc)),
        const SizedBox(height: Dimensions.spaceL),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentModel document) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.documentViewer,
            arguments: document,
          );
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: _getDocumentTypeColor(document.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  _getDocumentIcon(document.category),
                  color: _getDocumentTypeColor(document.category),
                  size: 32,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      'تم الرفع: ${DateFormat('yyyy-MM-dd').format(document.uploadedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (document.requiresSignature && !document.isSigned)
                      Row(
                        children: [
                          Icon(Icons.edit, size: 12, color: AppColors.warning),
                          const SizedBox(width: Dimensions.spaceXS),
                          Text(
                            'يتطلب التوقيع',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Icon(
                document.isSigned ? Icons.verified : Icons.arrow_forward_ios,
                size: 20,
                color: document.isSigned ? AppColors.success : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'contract':
        return 'العقود';
      case 'kyc':
        return 'وثائق التحقق';
      case 'invoice':
        return 'الفواتير';
      case 'report':
        return 'التقارير';
      case 'handover':
        return 'وثائق التسليم';
      default:
        return 'أخرى';
    }
  }

  IconData _getDocumentIcon(String category) {
    switch (category) {
      case 'contract':
        return Icons.description;
      case 'kyc':
        return Icons.verified_user;
      case 'invoice':
        return Icons.receipt;
      case 'report':
        return Icons.assessment;
      case 'handover':
        return Icons.home_work;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentTypeColor(String category) {
    switch (category) {
      case 'contract':
        return AppColors.primary;
      case 'kyc':
        return AppColors.success;
      case 'invoice':
        return AppColors.warning;
      case 'report':
        return Colors.purple;
      case 'handover':
        return Colors.teal;
      default:
        return AppColors.textSecondary;
    }
  }
}
