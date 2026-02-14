import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/edit_project_dialog.dart';

class ProjectTable extends StatelessWidget {
  final List<ProjectModel> projects;

  const ProjectTable({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            AppColors.primary.withOpacity(0.05),
          ),
          columns: const [
            DataColumn(label: Text('اسم المشروع')),
            DataColumn(label: Text('الموقع')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('نسبة الإنجاز')),
            DataColumn(label: Text('الوحدات')),
            DataColumn(label: Text('الإجراءات')),
          ],
          rows:
              projects.map((project) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          if (project.imageUrl != null)
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: NetworkImage(project.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Text(
                            project.nameAr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(project.locationName ?? '-')),
                    DataCell(_buildStatusChip(project.status)),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${project.completionPercentage}%'),
                          SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(
                              value: (project.completionPercentage ?? 0) / 100,
                              backgroundColor: Colors.grey[200],
                              color: _getProgressColor(
                                project.completionPercentage ?? 0,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text('${project.soldUnits}/${project.totalUnits}'),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EditProjectDialog(project: project),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.construction,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            tooltip: 'تحديثات التنفيذ',
                            onPressed: () {
                              // Navigate to construction updates tab with this project selected
                              // Or show a dialog directly
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                              size: 20,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(context, project);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    Color color;
    String label;

    switch (status) {
      case ProjectStatus.planning:
        color = AppColors.textSecondary;
        label = 'التخطيط';
        break;
      case ProjectStatus.upcoming:
        color = AppColors.info;
        label = 'قريباً';
        break;
      case ProjectStatus.inProgress:
        color = AppColors.primary;
        label = 'قيد التنفيذ';
        break;
      case ProjectStatus.completed:
        color = AppColors.success;
        label = 'مكتمل';
        break;
      case ProjectStatus.soldOut:
        color = AppColors.error;
        label = 'مباع بالكامل';
        break;
      case ProjectStatus.onHold:
        color = Colors.orange;
        label = 'متوقف مؤقتاً';
        break;
      case ProjectStatus.cancelled:
        color = Colors.red;
        label = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 100) return AppColors.success;
    if (percentage >= 70) return AppColors.primary;
    if (percentage >= 30) return AppColors.warning;
    return AppColors.error;
  }

  void _showDeleteConfirmation(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: Text('هل أنت متأكد من حذف مشروع "${project.nameAr}"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProjectsCubit>().deleteProject(project.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
