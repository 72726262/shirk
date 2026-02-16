import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';

class ProjectSelectionDialog extends StatefulWidget {
  const ProjectSelectionDialog({super.key});

  @override
  State<ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<ProjectSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'اختر المشروع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'بحث عن مشروع...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ProjectsCubit, ProjectsState>(
                builder: (context, state) {
                  if (state is ProjectsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ProjectsLoaded) {
                    final filteredProjects = state.projects.where((project) {
                      return project.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          project.nameAr
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredProjects.isEmpty) {
                      return const Center(child: Text('لا توجد مشاريع'));
                    }

                    return ListView.separated(
                      itemCount: filteredProjects.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final project = filteredProjects[index];
                        return ListTile(
                          title: Text(project.nameAr),
                          subtitle: Text(project.name),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              image: project.imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(project.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: project.imageUrl.isEmpty
                                ? const Icon(Icons.business,
                                    color: AppColors.primary)
                                : null,
                          ),
                          onTap: () {
                            Navigator.pop(context, project);
                          },
                        );
                      },
                    );
                  } else if (state is ProjectsError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
