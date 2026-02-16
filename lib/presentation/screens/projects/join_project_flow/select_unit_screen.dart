import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class SelectUnitScreen extends StatefulWidget {
  final String projectId;
  final ProjectModel? project; // اختياري

  const SelectUnitScreen({super.key, required this.projectId, this.project});

  @override
  State<SelectUnitScreen> createState() => _SelectUnitScreenState();
}

class _SelectUnitScreenState extends State<SelectUnitScreen> {
  bool _viewMode = false; // false = grid, true = list

  @override
  void initState() {
    super.initState();
    context.read<JoinFlowCubit>().loadAvailableUnits(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الوحدة'),
        actions: [
          IconButton(
            icon: Icon(_viewMode ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _viewMode = !_viewMode;
              });
            },
          ),
        ],
      ),
      body: BlocConsumer<JoinFlowCubit, JoinFlowState>(
        listener: (context, state) {
          if (state is JoinFlowError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is JoinFlowLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UnitSelectionState) {
            final units = state.availableUnits;
            final selectedUnit = state.selectedUnit;

            if (units.isEmpty) {
              return const Center(child: Text('لا توجد وحدات متاحة'));
            }

            return Column(
              children: [
                Expanded(
                  child: _viewMode
                      ? _buildUnitsList(units, selectedUnit)
                      : _buildUnitsGrid(units, selectedUnit),
                ),
                if (selectedUnit != null)
                  _buildSelectedUnitSummary(context, selectedUnit),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUnitsGrid(List<UnitModel> units, UnitModel? selectedUnit) {
    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Dimensions.spaceL,
        mainAxisSpacing: Dimensions.spaceL,
        childAspectRatio: 0.9,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final isSelected = selectedUnit?.id == unit.id;
        final isAvailable =
            unit.status == 'available'; // Assuming 'available' string or Enum

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  context.read<JoinFlowCubit>().selectUnit(unit);
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder Image (since unit model might not have image yet)
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.apartment,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit ${unit.unitNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${unit.price} SAR',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitsList(List<UnitModel> units, UnitModel? selectedUnit) {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final isSelected = selectedUnit?.id == unit.id;
        return ListTile(
          title: Text('Unit ${unit.unitNumber}'),
          subtitle: Text('${unit.price} SAR'),
          selected: isSelected,
          onTap: () => context.read<JoinFlowCubit>().selectUnit(unit),
        );
      },
    );
  }

  Widget _buildSelectedUnitSummary(BuildContext context, UnitModel unit) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unit Selected',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  unit.unitNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                RouteNames.contractSummary,
                arguments: {'projectId': widget.projectId, 'unitId': unit.id},
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
