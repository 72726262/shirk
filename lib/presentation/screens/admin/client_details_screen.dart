// lib/presentation/screens/admin/client_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/presentation/screens/admin/edit_client_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final UserModel client;

  const ClientDetailsScreen({super.key, required this.client});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final TextEditingController _rejectionReasonController =
      TextEditingController();

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
        ],
      ),
      body: BlocConsumer<ClientManagementCubit, ClientManagementState>(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
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
                _buildKycSection(),
                const SizedBox(height: Dimensions.spaceXL),
                if (widget.client.kycStatus ==
                    KYCStatus.underReview) // ✅ Fix enum
                  _buildActionButtons(isLoading),
              ],
            ),
          );
        },
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
            _buildInfoRow(
              'الاسم الكامل',
              widget.client.fullName ?? '-',
            ), // ✅ Fix nullable
            _buildInfoRow('البريد الإلكتروني', widget.client.email),
            _buildInfoRow(
              'رقم الهاتف',
              widget.client.phone ?? '-',
            ), // ✅ Fix field name
            _buildInfoRow(
              'تاريخ الميلاد',
              widget.client.dateOfBirth != null
                  ? DateFormat('dd/MM/yyyy').format(widget.client.dateOfBirth!)
                  : '-',
            ),
            _buildInfoRow('الرقم الوطني', widget.client.nationalId ?? '-'),
            _buildInfoRow(
              'حالة KYC',
              _getKycStatusLabel(
                widget.client.kycStatus,
              ), // ✅ Pass enum directly
              valueColor: _getKycStatusColor(widget.client.kycStatus),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مستندات التحقق (KYC)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: Dimensions.spaceL),
            if (widget.client.idFrontUrl != null) ...[
              // ✅ Fix field name
              _buildDocumentCard(
                'صورة الهوية (الأمام)',
                widget.client.idFrontUrl!,
              ),
              const SizedBox(height: Dimensions.spaceM),
            ],
            if (widget.client.idBackUrl != null) ...[
              // ✅ Fix field name
              _buildDocumentCard(
                'صورة الهوية (الخلف)',
                widget.client.idBackUrl!,
              ),
              const SizedBox(height: Dimensions.spaceM),
            ],
            if (widget.client.selfieUrl != null) ...[
              // ✅ Fix field name
              _buildDocumentCard('صورة السيلفي', widget.client.selfieUrl!),
              const SizedBox(height: Dimensions.spaceM),
            ],
            if (widget.client.incomeProofUrl != null) ...[
              // ✅ Fix field name
              _buildDocumentCard('إثبات الدخل', widget.client.incomeProofUrl!),
            ],
            if (widget.client.kycSubmittedAt != null) ...[
              const SizedBox(height: Dimensions.spaceM),
              Text(
                'تاريخ الإرسال: ${DateFormat('dd/MM/yyyy - HH:mm').format(widget.client.kycSubmittedAt!)}', // ✅ Already DateTime
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
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

  Widget _buildDocumentCard(String title, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(Dimensions.radiusM),
            ),
            child: _SecureImage(imageUrl: imageUrl),
          ),
        ],
      ),
    );
  }

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
              context.read<ClientManagementCubit>().approveKyc(
                widget.client.id,
              );
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
    // ✅ Fix enum
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
    // ✅ Fix enum
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

  const _SecureImage({required this.imageUrl});

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
      final pathSegments = uri.pathSegments; // Corrected from pathSeconds

      // Typical path: /storage/v1/object/public/bucket_name/path/to/file
      // segments: [storage, v1, object, public, bucket_name, path, to, file]

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
            height: 300,
            color: AppColors.surface,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 300,
            color: AppColors.surface,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: AppColors.error, size: 48),
                  SizedBox(height: Dimensions.spaceS),
                  Text('رابط غير صالح'),
                ],
              ),
            ),
          );
        }

        return Image.network(
          snapshot.data!,
          width: double.infinity,
          height: 300,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: AppColors.surface,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: AppColors.error, size: 48),
                    SizedBox(height: Dimensions.spaceS),
                    Text('فشل تحميل الصورة'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
