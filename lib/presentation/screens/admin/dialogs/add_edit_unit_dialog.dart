import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/project_selection_dialog.dart';
import 'package:mmm/data/repositories/units_repository.dart';

class AddEditUnitDialog extends StatefulWidget {
  final UnitModel? unit;

  final ProjectModel? project;

  const AddEditUnitDialog({super.key, this.unit, this.project});

  @override
  State<AddEditUnitDialog> createState() => _AddEditUnitDialogState();
}

class _AddEditUnitDialogState extends State<AddEditUnitDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _unitNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  // State values
  ProjectModel? _selectedProject;
  UnitStatus _status = UnitStatus.available;
  UnitType _unitType = UnitType.apartment;

  @override
  void initState() {
    super.initState();
    if (widget.unit != null) {
      _unitNumberController.text = widget.unit!.unitNumber;
      _floorController.text = widget.unit!.floor?.toString() ?? '';
      _areaController.text = widget.unit!.areaSqm.toString();
      _priceController.text = widget.unit!.price.toString();
      _bedroomsController.text = widget.unit!.bedrooms?.toString() ?? '';
      _bathroomsController.text = widget.unit!.bathrooms?.toString() ?? '';
      _status = widget.unit!.status;
      _unitType = widget.unit!.unitType ?? UnitType.apartment;
      // Note: We don't have the full ProjectModel here, just projectId.
      // Ideally we would fetch it or just display the ID if strictly necessary, 
      // but the user wants to select a project. 
      // For editing, we might not allow changing the project easily or we just keep the ID.
      // We'll handle this by validation.
    } else if (widget.project != null) {
      _selectedProject = widget.project;
      _fetchNextUnitNumber();
    }
  }

  Future<void> _fetchNextUnitNumber() async {
    if (_selectedProject == null) return;
    try {
      final nextNum = await context.read<UnitsRepository>().getNextUnitNumber(_selectedProject!.id);
      if (mounted) {
        setState(() {
          _unitNumberController.text = nextNum;
        });
      }
    } catch (e) {
      // Ignore error, user can type manually
      // debugPrint('Failed to fetch next unit number: $e');
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _selectProject() async {
    if (widget.project != null) return;

    final result = await showDialog<ProjectModel>(
      context: context,
      builder: (context) => const ProjectSelectionDialog(),
    );

    if (result != null) {
      setState(() {
        _selectedProject = result;
      });
      _fetchNextUnitNumber();
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.unit == null && _selectedProject == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار المشروع')),
        );
        return;
      }

      final unit = UnitModel(
        id: widget.unit?.id ?? '', // ID ignored on create
        projectId: _selectedProject?.id ?? widget.unit!.projectId,
        unitNumber: _unitNumberController.text,
        floor: int.tryParse(_floorController.text),
        areaSqm: double.parse(_areaController.text),
        price: double.parse(_priceController.text),
        status: _status,
        unitType: _unitType,
        bedrooms: int.tryParse(_bedroomsController.text),
        bathrooms: int.tryParse(_bathroomsController.text),
        createdAt: widget.unit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.unit == null) {
        context.read<UnitsManagementCubit>().addUnit(unit);
      } else {
        context.read<UnitsManagementCubit>().updateUnit(unit);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.unit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'تعديل الوحدة' : 'إضافة وحدة جديدة',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Project Selection
                const Text('المشروع', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: widget.project != null ? null : _selectProject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.project != null ? Colors.grey.shade100 : null,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text(
                          _selectedProject?.nameAr ?? 
                          (isEditing ? 'المشروع الحالي (اضغط للتغيير)' : 'اختر المشروع'),
                          style: TextStyle(
                            color: _selectedProject == null && !isEditing 
                                ? Colors.grey 
                                : Colors.black,
                          ),
                        ),
                        if (widget.project == null) const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Unit Number & Floor
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitNumberController,
                        readOnly: true, // Auto-generated/Fixed
                        decoration: InputDecoration(
                          labelText: 'رقم الوحدة (تلقائي)',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        decoration: const InputDecoration(
                          labelText: 'الدور',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Area & Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'المساحة (م²)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type & Status
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<UnitType>(
                        value: _unitType,
                        decoration: const InputDecoration(
                          labelText: 'النوع',
                          border: OutlineInputBorder(),
                        ),
                        items: UnitType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _unitType = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<UnitStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'الحالة',
                          border: OutlineInputBorder(),
                        ),
                        items: UnitStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bedrooms & Bathrooms
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        decoration: const InputDecoration(
                          labelText: 'غرف النوم',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        decoration: const InputDecoration(
                          labelText: 'الحمامات',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 50),
                      ),
                      child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
