import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/widgets/custom/standard_unit_card.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';

class SelectUnitScreen extends StatefulWidget {
  final ProjectModel project;

  const SelectUnitScreen({super.key, required this.project});

  @override
  State<SelectUnitScreen> createState() => _SelectUnitScreenState();
}

class _SelectUnitScreenState extends State<SelectUnitScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'available'; // Default to available for investment

  @override
  void initState() {
    super.initState();
    context.read<JoinFlowCubit>().loadAvailableUnits(widget.project.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UnitModel> _filterUnits(List<UnitModel> units) {
    return units.where((unit) {
      // 1. Filter by Status (unless 'all')
      if (_selectedFilter != 'all' && unit.status.name != _selectedFilter) {
        return false;
      }
      
      // 2. Filter by Search
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return unit.unitNumber.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('اختيار الوحدة')),
      body: BlocBuilder<JoinFlowCubit, JoinFlowState>(
        builder: (context, state) {
          if (state is JoinFlowLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is JoinFlowError) {
            return Center(child: Text(state.message));
          }

          if (state is UnitSelectionState) {
            final filteredUnits = _filterUnits(state.availableUnits);

            return Column(
              children: [
                // Search and Filters
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  color: Colors.white,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _searchController,
                        label: 'بحث',
                        showLabel: false,
                        hint: 'بحث برقم الوحدة...',
                        prefixIcon: Icons.search,
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'الكل'),
                            const SizedBox(width: 8),
                            _buildFilterChip('available', 'متاح'),
                            const SizedBox(width: 8),
                            _buildFilterChip('reserved', 'محجوز'),
                            const SizedBox(width: 8),
                            _buildFilterChip('sold', 'مباع'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Units Grid
                Expanded(
                  child: filteredUnits.isEmpty
                      ? const Center(child: Text('لا توجد وحدات مطابقة'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(Dimensions.spaceM),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.70, // Adjust based on card content
                            crossAxisSpacing: Dimensions.spaceM,
                            mainAxisSpacing: Dimensions.spaceM,
                          ),
                          itemCount: filteredUnits.length,
                          itemBuilder: (context, index) {
                            return StandardUnitCard(
                              unit: filteredUnits[index],
                              project: widget.project,
                              // No edit/delete for client flow here
                              // The Card handles navigation to details via "Details & Booking" button
                            );
                          },
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: isSelected ? BorderSide.none : const BorderSide(color: AppColors.border),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
