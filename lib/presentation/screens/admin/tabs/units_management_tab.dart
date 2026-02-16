import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_edit_unit_dialog.dart';
import 'package:mmm/presentation/screens/admin/dialogs/project_selection_dialog.dart';

class UnitsManagementTab extends StatefulWidget {
  const UnitsManagementTab({super.key});

  @override
  State<UnitsManagementTab> createState() => _UnitsManagementTabState();
}

class _UnitsManagementTabState extends State<UnitsManagementTab> {
  ProjectModel? _filterProject;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<UnitsManagementCubit>().loadUnits();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddEditDialog([UnitModel? unit]) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UnitsManagementCubit>(),
        child: AddEditUnitDialog(unit: unit),
      ),
    );
  }

  Future<void> _filterByProject() async {
    final result = await showDialog<ProjectModel>(
      context: context,
      builder: (context) => const ProjectSelectionDialog(),
    );

    if (result != null) {
      setState(() {
        _filterProject = result;
      });
      _loadUnits();
    }
  }

  void _clearProjectFilter() {
    setState(() {
      _filterProject = null;
    });
    _loadUnits();
  }

  void _loadUnits() {
    context.read<UnitsManagementCubit>().loadUnits(projectId: _filterProject?.id);
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
    // Note: We return a Widget, not Scaffold, because this is a Tab inside a Dashboard
    // But we use CustomScrollView which requires a constrained height parent.
    // The AdminDashboard body provides this.
    return Container(
      color: AppColors.background,
      child: BlocBuilder<UnitsManagementCubit, UnitsManagementState>(
        builder: (context, state) {
          if (state is UnitsManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UnitsManagementError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${state.message}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUnits,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is UnitsManagementLoaded) {
            final units = state.units;
            final totalUnits = units.length;
            final availableUnits = units.where((u) => u.status == UnitStatus.available).length;
            final soldUnits = units.where((u) => u.status == UnitStatus.sold).length;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إدارة الوحدات',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'نظرة عامة على جميع الوحدات العقارية',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                             ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppColors.primary.withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة وحدة جديدة'),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        
                        // Stats Cards
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              Expanded(child: _buildStatCard('إجمالي الوحدات', totalUnits.toString(), AppColors.primary, Icons.apartment)),
                              const SizedBox(width: Dimensions.spaceM),
                              Expanded(child: _buildStatCard('متاح للبيع', availableUnits.toString(), AppColors.success, Icons.check_circle_outline)),
                              const SizedBox(width: Dimensions.spaceM),
                              Expanded(child: _buildStatCard('تم البيع', soldUnits.toString(), AppColors.error, Icons.monetization_on_outlined)),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: Dimensions.spaceL),
                        
                        // Filter Bar
                        Container(
                          padding: const EdgeInsets.all(Dimensions.spaceS),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              const Icon(Icons.filter_list, color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              // Project Filter
                              InkWell(
                                onTap: _filterByProject,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _filterProject != null ? AppColors.primary.withOpacity(0.1) : AppColors.gray100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _filterProject != null ? AppColors.primary : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _filterProject?.nameAr ?? 'كل المشاريع',
                                        style: TextStyle(
                                          color: _filterProject != null ? AppColors.primary : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_filterProject != null) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: _clearProjectFilter,
                                          child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                                        ),
                                      ] else
                                        const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Refresh Button
                              IconButton(
                                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                                onPressed: _loadUnits,
                                tooltip: 'تحديث البيانات',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Units Grid
                if (units.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.apartment_outlined, size: 80, color: AppColors.gray300),
                          const SizedBox(height: 16),
                          Text(
                            _filterProject != null
                                ? 'لا توجد وحدات في هذا المشروع'
                                : 'لا توجد وحدات مضافة حالياً',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('أضف وحدتك الأولى'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisSpacing: Dimensions.spaceM,
                        crossAxisSpacing: Dimensions.spaceM,
                        childAspectRatio: 0.85, 
                        mainAxisExtent: 280, 
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _UnitCard(
                          unit: units[index],
                          onEdit: () => _showAddEditDialog(units[index]),
                          onDelete: () => _deleteUnit(units[index].id),
                        ),
                        childCount: units.length,
                      ),
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Status
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          unit.unitNumber,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          unit.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                      size: 48,
                      color: AppColors.gray400.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),

                  const Divider(),
                  
                  // Details
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.areaSqm} م²',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                       Text(
                        '${unit.price.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.grey.shade300),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
