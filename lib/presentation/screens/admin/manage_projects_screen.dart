import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class ManageProjectsScreen extends StatefulWidget {
  const ManageProjectsScreen({super.key});

  @override
  State<ManageProjectsScreen> createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المشاريع'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, RouteNames.createProject),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectsLoadedAdmin) {
            final projects = state.projects;

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<AdminCubit>().refreshProjects();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusM),
                          image: project.imageUrl != null
                              ? DecorationImage(image: NetworkImage(project.imageUrl!), fit: BoxFit.cover)
                              : null,
                          color: AppColors.gray200,
                        ),
                        child: project.imageUrl == null ? const Icon(Icons.business) : null,
                      ),
                      title: Text(project.name),
                      subtitle: Text('${project.unitsCount} وحدة • ${project.status}'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                          const PopupMenuItem(value: 'units', child: Text('الوحدات')),
                          const PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                        onSelected: (value) => _handleProjectAction(value.toString(), project.id),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _handleProjectAction(String action, String projectId) {
    switch (action) {
      case 'edit':
        Navigator.pushNamed(context, RouteNames.editProject, arguments: projectId);
        break;
      case 'delete':
        _showDeleteConfirmation(projectId);
        break;
    }
  }

  void _showDeleteConfirmation(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المشروع؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              context.read<AdminCubit>().deleteProject(projectId);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
