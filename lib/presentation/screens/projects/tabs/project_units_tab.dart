import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_edit_unit_dialog.dart';

import 'package:mmm/presentation/widgets/custom/standard_unit_card.dart';

class ProjectUnitsTab extends StatefulWidget {
  final ProjectModel project;

  const ProjectUnitsTab({super.key, required this.project});

  @override
  State<ProjectUnitsTab> createState() => _ProjectUnitsTabState();
}

class _ProjectUnitsTabState extends State<ProjectUnitsTab> {
  UnitStatus? _filterStatus;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Load units scoped to this project
    context.read<UnitsManagementCubit>().loadUnits(
      projectId: widget.project.id,
    );
  }

  void _showAddEditDialog([UnitModel? unit]) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UnitsManagementCubit>(),
        child: AddEditUnitDialog(
          unit: unit,
          project: widget.project, // Pass project to pre-select it
        ),
      ),
    );
  }

  void _deleteUnit(String unitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الوحدة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<UnitsManagementCubit>().deleteUnit(unitId);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnitsManagementCubit, UnitsManagementState>(
      builder: (context, state) {
        if (state is UnitsManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UnitsManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('حدث خطأ: ${state.message}'),
                TextButton(
                  onPressed: () => context
                      .read<UnitsManagementCubit>()
                      .loadUnits(projectId: widget.project.id),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        if (state is UnitsManagementLoaded) {
          // Filter by status and search query
          final units = state.units.where((u) {
            final matchesStatus =
                _filterStatus == null || u.status == _filterStatus;
            final matchesSearch =
                _searchQuery.isEmpty ||
                u.unitNumber.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Actions Bar
              Padding(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'بحث برقم الوحدة...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusM,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceM,
                            vertical: Dimensions.spaceS,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceM),
                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UnitStatus>(
                          value: _filterStatus,
                          hint: const Text('كل الحالات'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('الكل'),
                            ),
                            ...UnitStatus.values.map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.displayName),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value;
                            });
                          },
                          icon: const Icon(Icons.filter_list),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grid Content
              if (units.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.apartment,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus != null
                              ? 'لا توجد وحدات بهذه الحالة'
                              : 'لا توجد وحدات في هذا المشروع بعد',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceL,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          childAspectRatio: 0.85,
                          mainAxisSpacing: Dimensions.spaceM,
                          crossAxisSpacing: Dimensions.spaceM,
                        ),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      return StandardUnitCard(
                        unit: units[index],
                        project: widget.project,
                        onEdit: () => _showAddEditDialog(units[index]),
                        onDelete: () => _deleteUnit(units[index].id),
                      );
                    },
                  ),
                ),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
