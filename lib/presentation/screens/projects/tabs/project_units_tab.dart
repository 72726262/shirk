import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_edit_unit_dialog.dart';
import 'package:mmm/data/repositories/units_repository.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/presentation/screens/units/unit_detail_booking_screen.dart';

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
    context.read<UnitsManagementCubit>().loadUnits(projectId: widget.project.id);
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
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
            final matchesStatus = _filterStatus == null || u.status == _filterStatus;
            final matchesSearch = _searchQuery.isEmpty || 
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
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
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
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.spaceM),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UnitStatus>(
                          value: _filterStatus,
                          hint: const Text('كل الحالات'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('الكل')),
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
                        const Icon(Icons.apartment, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus != null
                              ? 'لا توجد وحدات بهذه الحالة'
                              : 'لا توجد وحدات في هذا المشروع بعد',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.spaceL),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 0.85,
                      mainAxisSpacing: Dimensions.spaceM,
                      crossAxisSpacing: Dimensions.spaceM,
                    ),
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      return _UnitCard(
                        unit: units[index],
                        onEdit: () => _showAddEditDialog(units[index]),
                        onDelete: () => _deleteUnit(units[index].id),
                        project: widget.project,
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

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ProjectModel project;

  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
    required this.project,
  });

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.available:
        return AppColors.success;
      case UnitStatus.reserved:
        return AppColors.warning;
      case UnitStatus.sold:
        return AppColors.error;
      case UnitStatus.blocked:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(unit.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusM)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${unit.unitNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          unit.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Icon
                  Center(
                    child: Icon(
                      unit.unitType == UnitType.villa ? Icons.villa : Icons.apartment,
                      size: 40,
                      color: AppColors.gray300,
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 8),
                  const SizedBox(height: 4),
                  // Details
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.areaSqm} م²',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const Spacer(),
                      Text(
                        '${unit.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isAdmin = state is Authenticated &&
                  (state.user.role == 'admin' || state.user.role == 'super_admin');

              if (isAdmin) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.gray200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('تعديل'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: AppColors.gray200),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('حذف'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (unit.status == UnitStatus.available) {
                // Client View: Book Button -> Unit Details
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnitDetailBookingScreen(
                            project: project,
                            unit: unit,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('التفاصيل والحجز'),
                  ),
                );
              } else {
                 return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
