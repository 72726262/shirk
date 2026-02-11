import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/screens/common/map_picker_screen.dart'; // ✅ Add

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
  final _latController = TextEditingController(); // ✅ Add
  final _lngController = TextEditingController(); // ✅ Add
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
    _latController.dispose(); // ✅ Add
    _lngController.dispose(); // ✅ Add
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
                        label: 'اسم الموقع (مثال: القاهرة الجديدة)',
                        validator: (v) => v?.isNotEmpty == true ? null : 'مطلوب',
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      // ✅ Location Coordinates
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _latController,
                              label: 'خط العرض (Latitude)',
                              isNumber: true,
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'مطلوب';
                                final lat = double.tryParse(v!);
                                if (lat == null || lat < -90 || lat > 90) {
                                  return 'يجب أن يكون بين -90 و 90';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: _buildTextField(
                              controller: _lngController,
                              label: 'خط الطول (Longitude)',
                              isNumber: true,
                              validator: (v) {
                                if (v?.isEmpty ?? true) return 'مطلوب';
                                final lng = double.tryParse(v!);
                                if (lng == null || lng < -180 || lng > 180) {
                                  return 'يجب أن يكون بين -180 و 180';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      // ✅ Map Picker Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<Map<String, double>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerScreen(
                                initialLat: double.tryParse(_latController.text),
                                initialLng: double.tryParse(_lngController.text),
                              ),
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _latController.text = result['latitude']!.toStringAsFixed(6);
                              _lngController.text = result['longitude']!.toStringAsFixed(6);
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ تم تحديد الموقع بنجاح'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('اختر من الخريطة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
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
                  Flexible(
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
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('إضافة المشروع'),
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
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumber 
          ? const TextInputType.numberWithOptions(decimal: true) 
          : TextInputType.text,
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
        'location_lat': double.tryParse(_latController.text), // ✅ Add
        'location_lng': double.tryParse(_lngController.text), // ✅ Add
        'price_per_sqm': double.tryParse(_priceController.text) ?? 0,
        'min_investment': double.tryParse(_minInvestmentController.text) ?? 0,
        'max_investment': double.tryParse(_maxInvestmentController.text) ?? 0,
        'total_units': int.tryParse(_totalUnitsController.text) ?? 0,
        'status': 'upcoming',
        'completion_percentage': 0,
        'total_partners': 0,
        'featured': false,
        'is_active': true,
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
