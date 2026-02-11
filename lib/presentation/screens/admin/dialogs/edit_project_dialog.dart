import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';

class EditProjectDialog extends StatefulWidget {
  final ProjectModel project;

  const EditProjectDialog({super.key, required this.project});

  @override
  State<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nameArController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _completionController;
  
  bool _isLoading = false;
  late ProjectStatus _status;
  bool _featured = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _nameArController = TextEditingController(text: widget.project.nameAr);
    _locationController = TextEditingController(text: widget.project.locationName);
    _priceController = TextEditingController(text: widget.project.pricePerSqm?.toString());
    _completionController = TextEditingController(text: widget.project.completionPercentage?.toString());
    
    _status = widget.project.status;
    _featured = widget.project.featured;
    _isActive = widget.project.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _completionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تعديل المشروع',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameArController,
                              label: 'اسم المشروع (عربي)',
                              validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Project Name (English)',
                              validator: (v) => v?.isNotEmpty == true ? null : 'Required',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      _buildTextField(
                        controller: _locationController,
                        label: 'الموقع',
                        validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'سعر المتر',
                              isNumber: true,
                              validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: _buildTextField(
                              controller: _completionController,
                              label: 'نسبة الإنجاز (%)',
                              isNumber: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'مطلوب';
                                final val = double.tryParse(v);
                                if (val == null || val < 0 || val > 100) return '0-100';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      
                      const Text('الحالة والإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: Dimensions.spaceS),
                      DropdownButtonFormField<ProjectStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'حالة المشروع',
                          border: OutlineInputBorder(),
                        ),
                        items: ProjectStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      SwitchListTile(
                        title: const Text('مشروع مميز (Featured)'),
                        value: _featured,
                        onChanged: (val) => setState(() => _featured = val),
                      ),
                      SwitchListTile(
                        title: const Text('نشط (Active)'),
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ التعديلات'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _nameController.text,
        'name_ar': _nameArController.text,
        'location_name': _locationController.text,
        'price_per_sqm': double.tryParse(_priceController.text) ?? 0,
        'completion_percentage': double.tryParse(_completionController.text) ?? 0,
        'status': _status.name,
        'featured': _featured,
        'is_active': _isActive,
      };

      await context.read<ProjectsCubit>().updateProject(widget.project.id, updates);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل المشروع بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
