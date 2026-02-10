import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameArController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _minInvestmentController = TextEditingController();
  final _maxInvestmentController = TextEditingController();
  final _totalUnitsController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _minInvestmentController.dispose();
    _maxInvestmentController.dispose();
    _totalUnitsController.dispose();
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
        constraints: BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'إضافة مشروع جديد',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
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
                              controller: _totalUnitsController,
                              label: 'عدد الوحدات',
                              isNumber: true,
                              validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _minInvestmentController,
                              label: 'الحد الأدنى للاستثمار',
                              isNumber: true,
                              validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: _buildTextField(
                              controller: _maxInvestmentController,
                              label: 'الحد الأقصى للاستثمار',
                              isNumber: true,
                              validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                            ),
                          ),
                        ],
                      ),
                      // TODO: Add Image Picker for Hero Image
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('إضافة المشروع'),
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
      final projectData = {
        'name': _nameController.text,
        'name_ar': _nameArController.text,
        'location_name': _locationController.text,
        'price_per_sqm': double.tryParse(_priceController.text) ?? 0,
        'min_investment': double.tryParse(_minInvestmentController.text) ?? 0,
        'max_investment': double.tryParse(_maxInvestmentController.text) ?? 0,
        'total_units': int.tryParse(_totalUnitsController.text) ?? 0,
        'status': 'upcoming',
        'completion_percentage': 0,
        'total_partners': 0,
        'featured': false,
        'is_active': true,
        // 'created_by': ... (handled by backend or repository if auth triggers)
      };

      await context.read<ProjectsCubit>().addProject(projectData);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المشروع بنجاح')),
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
