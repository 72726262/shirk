// lib/presentation/screens/admin/client_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/repositories/document_repository.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/presentation/screens/admin/edit_client_screen.dart';
import 'package:mmm/presentation/screens/common/document_viewer_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final UserModel client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  final DocumentRepository _documentRepository = DocumentRepository();
  List<DocumentModel> _clientDocuments = [];
  bool _isLoadingDocuments = true;
  bool _isDeleting = false; // Add this state variable

  @override
  void initState() {
    super.initState();
    _fetchClientDocuments();
  }

  Future<void> _fetchClientDocuments() async {
    try {
      final docs = await _documentRepository.getUserDocuments(
        userId: widget.client.id,
      );
      if (mounted) {
        setState(() {
          _clientDocuments = docs;
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocuments = false);
        // Silently fail or show snackbar? Low priority for now.
        print('Error fetching documents: $e');
      }
    }
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العميل'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editClient(context),
            tooltip: 'تعديل البيانات',
          ),
          IconButton(
             icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () => _confirmDeleteClient(),
            tooltip: 'حذف العميل',
          ),
        ],
      ),
      body: Stack(
        children: [
          BlocConsumer<ClientManagementCubit, ClientManagementState>(
            listener: (context, state) {
              if (state is KycApproved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تمت الموافقة على KYC بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is KycRejected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم رفض KYC'),
                    backgroundColor: AppColors.error,
                  ),
                );
                Navigator.pop(context, true);
              } else if (state is ClientManagementError) {
                // Only show error if NOT deleting (since delete handles its own error)
                if (!_isDeleting) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            builder: (context, state) {
              final isLoading = state is ClientManagementLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(),
                    const SizedBox(height: Dimensions.spaceXL),
                    _buildCombinedDocumentsSection(), // Unified documents section
                    const SizedBox(height: Dimensions.spaceXL),
                    if (widget.client.kycStatus == KYCStatus.underReview)
                      _buildActionButtons(isLoading),
                  ],
                ),
              );
            },
          ),
          
          // Loading Overlay
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري حذف العميل والبيانات المرتبطة...'),
                         Text('قد تستغرق العملية بضع ثوانٍ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المعلومات الأساسية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: Dimensions.spaceL),
            _buildInfoRow('الاسم الكامل', widget.client.fullName ?? '-'),
            _buildInfoRow('البريد الإلكتروني', widget.client.email),
            _buildInfoRow('رقم الهاتف', widget.client.phone ?? '-'),
            _buildInfoRow(
              'تاريخ الميلاد',
              widget.client.dateOfBirth != null
                  ? DateFormat('dd/MM/yyyy').format(widget.client.dateOfBirth!)
                  : '-',
            ),
            _buildInfoRow('الرقم الوطني', widget.client.nationalId ?? '-'),
            _buildInfoRow(
              'حالة KYC',
              _getKycStatusLabel(widget.client.kycStatus),
              valueColor: _getKycStatusColor(widget.client.kycStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المستندات والوثائق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingDocuments)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const Divider(height: Dimensions.spaceL),
            
            // KYC Documents
            if (widget.client.idFrontUrl != null || 
                widget.client.idBackUrl != null || 
                widget.client.selfieUrl != null || 
                widget.client.incomeProofUrl != null) ...[
              const Text(
                'مستندات KYC',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: Dimensions.spaceM),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: Dimensions.spaceM,
                mainAxisSpacing: Dimensions.spaceM,
                childAspectRatio: 0.8,
                children: [
                  if (widget.client.idFrontUrl != null)
                    _buildDocumentThumbnail('صورة الهوية (الأمام)', widget.client.idFrontUrl!, DocumentViewerType.image),
                  if (widget.client.idBackUrl != null)
                    _buildDocumentThumbnail('صورة الهوية (الخلف)', widget.client.idBackUrl!, DocumentViewerType.image),
                  if (widget.client.selfieUrl != null)
                    _buildDocumentThumbnail('صورة السيلفي', widget.client.selfieUrl!, DocumentViewerType.image),
                  if (widget.client.incomeProofUrl != null)
                     // Income proof might be PDF or Image. Assuming image for now based on previous implementation, 
                     // or we check extension/type if available. 
                     // For simplicity, let's treat as image unless we know otherwise.
                     // A safer bet is to assume image for now.
                    _buildDocumentThumbnail('إثبات الدخل', widget.client.incomeProofUrl!, DocumentViewerType.image), 
                    
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],

            // Other Documents (from Documents table)
            if (_clientDocuments.isNotEmpty) ...[
               const Text(
                'مستندات أخرى',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: Dimensions.spaceM),
               GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimensions.spaceM,
                  mainAxisSpacing: Dimensions.spaceM,
                  childAspectRatio: 0.8,
                ),
                itemCount: _clientDocuments.length,
                itemBuilder: (context, index) {
                  final doc = _clientDocuments[index];
                  final isPdf = doc.mimeType == 'application/pdf' || doc.fileUrl.toLowerCase().endsWith('.pdf');
                  return _buildDocumentThumbnail(
                    doc.title, 
                    doc.fileUrl, 
                    isPdf ? DocumentViewerType.pdf : DocumentViewerType.image,
                  );
                },
              ),
            ] else if (!_isLoadingDocuments && 
                       widget.client.idFrontUrl == null && 
                       widget.client.idBackUrl == null &&
                       widget.client.selfieUrl == null &&
                       widget.client.incomeProofUrl == null) ...[
               const Center(child: Text('لا توجد مستندات لعرضها')),
            ],

            if (widget.client.kycRejectionReason != null) ...[
              const SizedBox(height: Dimensions.spaceM),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سبب الرفض:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      widget.client.kycRejectionReason!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail(String title, String url, DocumentViewerType type) {
    return GestureDetector(
      onTap: () async {
        // Resolve signed URL first if needed
        final resolvedUrl = await _resolveImageUrl(url);
        if (context.mounted) {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(
                url: resolvedUrl,
                type: type,
                title: title,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
          color: AppColors.surface,
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusM)),
                child: type == DocumentViewerType.pdf 
                    ? const Center(child: Icon(Icons.picture_as_pdf, size: 50, color: AppColors.error))
                    : _SecureImage(imageUrl: url, thumbnail: true),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceS),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Dimensions.radiusM)),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Copied from below SecureImage widget and made static-like for utility
  Future<String> _resolveImageUrl(String url) async {
     // Check if it's a Supabase Storage URL
    if (url.contains('/storage/v1/object/public/')) {
      final uri = Uri.parse(url);

      try {
        final publicIndex = uri.pathSegments.indexOf('public');
        if (publicIndex != -1 && publicIndex + 1 < uri.pathSegments.length) {
          final bucketName = uri.pathSegments[publicIndex + 1];
          // Check if it's a private bucket we know of
          if (bucketName == 'kyc-documents' || bucketName == 'documents') {
            final filePath = uri.pathSegments
                .sublist(publicIndex + 2)
                .join('/');

            // Generate Signed URL
            final signedUrl = await Supabase.instance.client.storage
                .from(bucketName)
                .createSignedUrl(filePath, 3600); // 1 hour expiry

            return signedUrl;
          }
        }
      } catch (e) {
        debugPrint('Error parsing Supabase URL: $e');
      }
    }
    return url;
  }

  // ... (Rest of existing methods: _buildActionButtons, _buildInfoRow, _approveKyc, _showRejectDialog, _getKycStatusLabel, _getKycStatusColor, _editClient) ...
  // Re-implementing them here to ensure they are available in the replaced content
  
  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _approveKyc(),
            icon: const Icon(Icons.check_circle),
            label: const Text('الموافقة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(Dimensions.spaceM),
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => _showRejectDialog(),
            icon: const Icon(Icons.cancel),
            label: const Text('رفض'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(Dimensions.spaceM),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient() {
    // Capture the screen context before showing the dialog
    final screenContext = context;

    showDialog(
      context: screenContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف العميل'),
        content: const Text(
          'هل أنت متأكد من حذف هذا العميل؟ لا يمكن التراجع عن هذا الإجراء.\n\nسيتم حذف جميع البيانات المرتبطة: الاشتراكات، العقود، الدفعات، إلخ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close confirmation dialog
              
              if (!mounted) return;

              setState(() {
                _isDeleting = true;
              });

              try {
                // Use screenContext to access the Cubit
                await screenContext.read<ClientManagementCubit>().deleteClient(widget.client.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم حذف العميل بنجاح'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(screenContext, true); // Close details screen
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                  
                  ScaffoldMessenger.of(screenContext).showSnackBar(
                    SnackBar(
                      content: Text('❌ حدث خطأ: ${e.toString().replaceAll('Exception:', '')}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              }
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


  void _approveKyc() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: const Text(
          'هل أنت متأكد من الموافقة على مستندات التحقق لهذا العميل?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ClientManagementCubit>().approveKyc(widget.client.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض التحقق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى تحديد سبب الرفض:'),
            const SizedBox(height: Dimensions.spaceM),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_rejectionReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة سبب الرفض'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              context.read<ClientManagementCubit>().rejectKyc(
                widget.client.id,
                _rejectionReasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  String _getKycStatusLabel(KYCStatus status) {
    switch (status) {
      case KYCStatus.pending:
        return 'قيد الانتظار';
      case KYCStatus.underReview:
        return 'قيد المراجعة';
      case KYCStatus.approved:
        return '✅ موافَق عليه';
      case KYCStatus.rejected:
        return '❌ مرفوض';
    }
  }

  Color _getKycStatusColor(KYCStatus status) {
    switch (status) {
      case KYCStatus.approved:
        return AppColors.success;
      case KYCStatus.rejected:
        return AppColors.error;
      case KYCStatus.underReview:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _editClient(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ClientManagementCubit>(),
          child: EditClientScreen(client: widget.client),
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _SecureImage extends StatefulWidget {
  final String imageUrl;
  final bool thumbnail; // Add thumbnail mode

  const _SecureImage({required this.imageUrl, this.thumbnail = false});

  @override
  State<_SecureImage> createState() => _SecureImageState();
}

class _SecureImageState extends State<_SecureImage> {
  late Future<String> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _resolveImageUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _SecureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _resolveImageUrl(widget.imageUrl);
    }
  }

  Future<String> _resolveImageUrl(String url) async {
    // Check if it's a Supabase Storage URL
    if (url.contains('/storage/v1/object/public/')) {
      final uri = Uri.parse(url);

      try {
        final publicIndex = uri.pathSegments.indexOf('public');
        if (publicIndex != -1 && publicIndex + 1 < uri.pathSegments.length) {
          final bucketName = uri.pathSegments[publicIndex + 1];
          // Check if it's a private bucket we know of
          if (bucketName == 'kyc-documents' || bucketName == 'documents') {
            final filePath = uri.pathSegments
                .sublist(publicIndex + 2)
                .join('/');

            // Generate Signed URL
            final signedUrl = await Supabase.instance.client.storage
                .from(bucketName)
                .createSignedUrl(filePath, 3600); // 1 hour expiry

            return signedUrl;
          }
        }
      } catch (e) {
        debugPrint('Error parsing Supabase URL: $e');
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: widget.thumbnail ? null : 300,
            color: AppColors.surface,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: widget.thumbnail ? null : 300,
            color: AppColors.surface,
            child: const Center(
              child: Icon(Icons.broken_image, color: AppColors.error, size: 24),
            ),
          );
        }

        return Image.network(
          snapshot.data!,
          width: double.infinity,
          height: widget.thumbnail ? null : 300,
          fit: widget.thumbnail ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: widget.thumbnail ? null : 300,
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.error, color: AppColors.error, size: 24),
              ),
            );
          },
        );
      },
    );
  }
}

