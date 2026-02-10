import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedType;
  PlatformFile? _selectedFile;

  final List<String> _documentTypes = [
    'عقد',
    'هوية',
    'شهادة',
    'فاتورة',
    'أخرى',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رفع مستند'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<DocumentsCubit, DocumentsState>(
        listener: (context, state) {
          if (state is DocumentUploaded) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم رفع المستند بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final isUploading = state is DocumentsLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.cloud_upload, size: 80, color: AppColors.primary),
                  const SizedBox(height: Dimensions.spaceXL),

                  Text(
                    'رفع مستند جديد',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // File Picker
                  GestureDetector(
                    onTap: isUploading ? null : _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(Dimensions.spaceXL),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        border: Border.all(
                          color: _selectedFile != null
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.insert_drive_file
                                : Icons.upload_file,
                            size: 48,
                            color: _selectedFile != null
                                ? AppColors.primary
                                : AppColors.gray400,
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          Text(
                            _selectedFile?.name ?? 'اضغط لاختيار ملف',
                            style: TextStyle(
                              color: _selectedFile != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _selectedFile != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedFile != null) ...[
                            const SizedBox(height: Dimensions.spaceS),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Document Name
                  CustomTextField(
                    controller: _nameController,
                    label: 'اسم المستند',
                    prefixIcon: Icon(Icons.description),

                    validator: (v) =>
                        v?.isEmpty ?? true ? 'الرجاء إدخال اسم المستند' : null,
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Document Type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'نوع المستند',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _documentTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: isUploading
                        ? null
                        : (value) {
                            setState(() => _selectedType = value);
                          },
                    validator: (v) =>
                        v == null ? 'الرجاء اختيار نوع المستند' : null,
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Upload Button
                  PrimaryButton(
                    text: 'رفع المستند',
                    onPressed: isUploading ? () {} : _uploadDocument,
                    isLoading: isUploading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار ملف'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    await context.read<DocumentsCubit>().uploadDocument(
      userId: authState.user.id,
      title: _nameController.text,
      type: _getDocumentType(_selectedType!),
      filePath: _selectedFile!.path!,
    );
  }

  DocumentType _getDocumentType(String type) {
    switch (type) {
      case 'عقد':
        return DocumentType.contract;
      case 'هوية':
        return DocumentType.idCard;
      case 'شهادة':
        return DocumentType.certificate;
      case 'فاتورة':
        return DocumentType.invoice;
      default:
        return DocumentType.other;
    }
  }
}
