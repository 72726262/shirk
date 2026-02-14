import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';

import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_state.dart';

class UploadDocumentScreen extends StatefulWidget {
  final DocumentModel? document;

  const UploadDocumentScreen({super.key, this.document});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedProjectId;
  DocumentType _selectedType = DocumentType.other;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();

    // Load data
    context.read<ClientManagementCubit>().loadClients();
    context.read<ProjectsCubit>().loadProjects();

    // Fill data if editing
    if (widget.document != null) {
      _selectedClientId = widget.document!.userId;
      _selectedProjectId = widget.document!.projectId;
      _selectedType = widget.document!.type;
      _titleController.text = widget.document!.title;
      _descriptionController.text = widget.document!.description ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        if (_titleController.text.isEmpty) {
          _titleController.text = _selectedFile!.name;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار العميل'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_selectedFile == null && widget.document == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار ملف'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (widget.document != null) {
        // Update existing document
        context.read<DocumentsManagementCubit>().updateDocument(
          documentId: widget.document!.id,
          title: _titleController.text,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          type: _selectedType,
          projectId: _selectedProjectId,
        );
      } else {
        // Upload new document
        context.read<DocumentsManagementCubit>().uploadDocument(
          userId: _selectedClientId!,
          projectId: _selectedProjectId,
          title: _titleController.text,
          type: _selectedType,
          filePath: _selectedFile!.path!,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document != null ? 'تعديل المستند' : 'رفع مستند جديد',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<DocumentsManagementCubit, DocumentsManagementState>(
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
              SnackBar(
                content: Text(
                  widget.document != null
                      ? 'تم تعديل المستند بنجاح'
                      : 'تم رفع المستند بنجاح',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context); // Close screen
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === Client Selector ===
                const Text(
                  'العميل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: Dimensions.spaceS),
                BlocBuilder<ClientManagementCubit, ClientManagementState>(
                  builder: (context, state) {
                    if (state is ClientManagementLoading) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    List<UserModel> clients = [];
                    if (state is ClientManagementLoaded) {
                      clients = state.clients;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر العميل',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: clients.map((client) {
                        return DropdownMenuItem(
                          value: client.id,
                          child: Text(
                            '${client.fullName ?? 'غير محدد'} (${client.email})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClientId = value;
                        });
                      },
                      validator: (value) => value == null ? 'مطلوب' : null,
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Project Selector ===
                const Text(
                  'المشروع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: Dimensions.spaceS),
                BlocBuilder<ProjectsCubit, ProjectsState>(
                  builder: (context, state) {
                    if (state is ProjectsLoading) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    List<ProjectModel> projects = [];
                    if (state is ProjectsLoaded) {
                      projects = state.projects;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر المشروع (اختياري)',
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Document Type ===
                DropdownButtonFormField<DocumentType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'نوع المستند',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: DocumentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getDocumentTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Title ===
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المستند',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Description ===
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'وصف (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === File Picker ===
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      border: Border.all(
                        color: _selectedFile == null
                            ? AppColors.gray300
                            : AppColors.primary,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedFile == null
                              ? Icons.cloud_upload
                              : Icons.check_circle,
                          size: 48,
                          color: _selectedFile == null
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                        const SizedBox(height: Dimensions.spaceS),
                        Text(
                          _selectedFile == null
                              ? 'اضغط لاختيار ملف'
                              : _selectedFile!.name,
                          style: TextStyle(
                            color: _selectedFile == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_selectedFile != null)
                          Text(
                            '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Submit Button ===
                BlocBuilder<DocumentsManagementCubit, DocumentsManagementState>(
                  builder: (context, state) {
                    if (state is DocumentsManagementUploading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        widget.document != null
                            ? 'حفظ التعديلات'
                            : 'رفع المستند',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.contract:
        return 'عقد';
      case DocumentType.kyc:
        return 'هوية / KYC';
      case DocumentType.receipt:
        return 'إيصال';
      case DocumentType.other:
        return 'أخرى';
      default:
        return 'غير محدد';
    }
  }
}
