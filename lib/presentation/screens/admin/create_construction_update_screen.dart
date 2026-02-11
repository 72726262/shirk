import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/services/storage_service.dart';
import 'package:mmm/data/services/construction_service.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/presentation/widgets/common/image_picker_widget.dart';
import 'package:mmm/presentation/widgets/common/file_upload_widget.dart';
import 'package:mmm/presentation/widgets/inputs/primary_text_field.dart';
import 'package:mmm/presentation/widgets/buttons/primary_button.dart';

class CreateConstructionUpdateScreen extends StatefulWidget {
  final String projectId;

  const CreateConstructionUpdateScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<CreateConstructionUpdateScreen> createState() =>
      _CreateConstructionUpdateScreenState();
}

class _CreateConstructionUpdateScreenState
    extends State<CreateConstructionUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ConstructionService _constructionService = ConstructionService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _weekNumberController = TextEditingController();
  final TextEditingController _completionController = TextEditingController();

  UpdateType _selectedType = UpdateType.progress;
  List<String> _photoPaths = [];
  List<String> _videoPaths = [];
  List<String> _reportPaths = [];
  bool _isPublic = true;
  bool _notifyClients = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء تحديث إنشائي'),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: Dimensions.screenPadding,
          children: [
            // Title
            PrimaryTextField(
              controller: _titleController,
              label: 'عنوان التحديث',
              hint: 'مثال: اكتمال صب الأساسات',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'العنوان مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Description
            PrimaryTextField(
              controller: _descriptionController,
              label: 'الوصف',
              hint: 'تفاصيل التحديث...',
              maxLines: 5,
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Update Type
            DropdownButtonFormField<UpdateType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع التحديث',
                border: OutlineInputBorder(),
              ),
              items: UpdateType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Week Number
            PrimaryTextField(
              controller: _weekNumberController,
              label: 'رقم الأسبوع',
              hint: '1',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: Dimensions.spaceL),

            // Completion Percentage
            PrimaryTextField(
              controller: _completionController,
              label: 'نسبة الإنجاز (%)',
              hint: '0-100',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final num = double.tryParse(value);
                  if (num == null || num < 0 || num > 100) {
                    return 'يجب أن تكون النسبة بين 0 و 100';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: Dimensions.spaceXL),

            // Photos Section
            const Text(
              'صور التحديث',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spaceM),
            FileUploadWidget(
              onFilesSelected: (files) {
                setState(() {
                  _photoPaths = files;
                });
              },
              allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
              allowMultiple: true,
              buttonText: 'إضافة صور',
              icon: Icons.add_photo_alternate,
              maxFiles: 10,
            ),
            const SizedBox(height: Dimensions.spaceXL),

            // Videos Section
            const Text(
              'فيديوهات التحديث',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spaceM),
            FileUploadWidget(
              onFilesSelected: (files) {
                setState(() {
                  _videoPaths = files;
                });
              },
              allowedExtensions: const ['mp4', 'mov', 'avi'],
              allowMultiple: true,
              buttonText: 'إضافة فيديوهات',
              icon: Icons.video_library,
              maxFiles: 5,
            ),
            const SizedBox(height: Dimensions.spaceXL),

            // Reports Section
            const Text(
              'التقارير',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spaceM),
            FileUploadWidget(
              onFilesSelected: (files) {
                setState(() {
                  _reportPaths = files;
                });
              },
              allowedExtensions: const ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
              allowMultiple: true,
              buttonText: 'إضافة تقارير',
              icon: Icons.attach_file,
              maxFiles: 3,
            ),
            const SizedBox(height: Dimensions.spaceXL),

            // Options
            CheckboxListTile(
              title: const Text('تحديث عام (يمكن للعملاء رؤيته)'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value!;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('إرسال إشعار للعملاء'),
              value: _notifyClients,
              onChanged: (value) {
                setState(() {
                  _notifyClients = value!;
                });
              },
            ),
            const SizedBox(height: Dimensions.spaceXL),

            // Submit Button
            PrimaryButton(
              onPressed: _isLoading ? null : _submitUpdate,
              text: 'نشر التحديث',
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(UpdateType type) {
    switch (type) {
      case UpdateType.milestone:
        return 'إنجاز';
      case UpdateType.progress:
        return 'تقدم';
      case UpdateType.delay:
        return 'تأخير';
      case UpdateType.completion:
        return 'اكتمال';
      default:
        return 'عام';
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final weekNumber = _weekNumberController.text.isNotEmpty
          ? int.tryParse(_weekNumberController.text)
          : null;
      final completion = _completionController.text.isNotEmpty
          ? double.tryParse(_completionController.text)
          : null;

      await _constructionService.createUpdate(
        projectId: widget.projectId,
        title: _titleController.text,
        titleAr: _titleController.text,
        description: _descriptionController.text,
        descriptionAr: _descriptionController.text,
        type: _selectedType,
        completionPercentage: completion,
        weekNumber: weekNumber,
        photosPaths: _photoPaths.isNotEmpty ? _photoPaths : null,
        videosPaths: _videoPaths.isNotEmpty ? _videoPaths : null,
        engineeringReportPath: _reportPaths.isNotEmpty ? _reportPaths[0] : null,
        financialReportPath: _reportPaths.length > 1 ? _reportPaths[1] : null,
        supervisionReportPath: _reportPaths.length > 2 ? _reportPaths[2] : null,
        isPublic: _isPublic,
        notifyClients: _notifyClients,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر التحديث بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weekNumberController.dispose();
    _completionController.dispose();
    super.dispose();
  }
}
