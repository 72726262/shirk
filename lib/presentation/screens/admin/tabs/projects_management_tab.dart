import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_project_dialog.dart';
import 'package:mmm/presentation/screens/admin/widgets/project_table.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';

class ProjectsManagementTab extends StatefulWidget {
  const ProjectsManagementTab({super.key});

  @override
  State<ProjectsManagementTab> createState() => _ProjectsManagementTabState();
}

class _ProjectsManagementTabState extends State<ProjectsManagementTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProjectsCubit>().loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: Dimensions.spaceL),
          Expanded(
            child: BlocBuilder<ProjectsCubit, ProjectsState>(
              builder: (context, state) {
                if (state is ProjectsLoading) {
                  return const SkeletonList();
                }

                if (state is ProjectsLoaded) {
                  if (state.projects.isEmpty) {
                    return const Center(child: Text('لا توجد مشاريع'));
                  }
                  return ProjectTable(projects: state.projects);
                }

                if (state is ProjectsError) {
                  return Center(child: Text(state.message));
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في المشاريع...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusM),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceM,
                vertical: Dimensions.spaceS,
              ),
            ),
            onChanged: (query) {
              // TODO: Implement search in Cubit
              // context.read<ProjectsCubit>().searchProjects(query);
            },
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('مشروع جديد'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.spaceL,
              vertical: Dimensions.spaceM,
            ),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const AddProjectDialog(),
            );
          },
        ),
      ],
    );
  }
}
