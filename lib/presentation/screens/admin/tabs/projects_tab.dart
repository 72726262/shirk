import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_project_dialog.dart';
import 'package:mmm/presentation/screens/projects/project_detail_full_screen.dart';
import 'package:shimmer/shimmer.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProjectsCubit, ProjectsState>(
        builder: (context, state) {
          if (state is ProjectsLoading) {
            return _buildSkeletonLoader();
          }

          if (state is ProjectsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Text(state.message),
                  const SizedBox(height: Dimensions.spaceM),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProjectsCubit>().loadProjects(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is ProjectsLoaded) {
            final projects = state.projects;

            if (projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 64,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text(
                      'لا توجد مشاريع حالياً',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _ProjectCard(project: project);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddProjectDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('مشروع جديد'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.gray200,
          highlightColor: AppColors.gray100,
          child: Container(
            margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 24,
                        width: 200,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Container(
                        height: 16,
                        width: 150,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Container(
                        height: 6,
                        width: double.infinity,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          3,
                          (i) => Container(
                            height: 60,
                            width: 80,
                            color: AppColors.gray300,
                          ),
                        ),
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
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.upcoming:
        return 'قيد الإعداد';
      case ProjectStatus.inProgress:
        return 'قيد التنفيذ';
      case ProjectStatus.completed:
        return 'مكتمل';
      case ProjectStatus.onHold:
        return 'متوقف';
      case ProjectStatus.soldOut:
        return 'مباع بالكامل';
      case ProjectStatus.cancelled:
        return 'ملغي';
    }
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return AppColors.primary;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.upcoming:
        return AppColors.info;
      case ProjectStatus.onHold:
        return AppColors.warning;
      case ProjectStatus.soldOut:
        return AppColors.accent;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completionPercentage = project.completionPercentage ?? 0.0;
    final availableUnits = project.availableUnits ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailFullScreen(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                    image: (project.imageUrl != null && project.imageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(project.imageUrl!),
                            fit: BoxFit.cover,
                            onError: (error, stackTrace) {},
                          )
                        : null,
                  ),
                  child: (project.imageUrl == null || project.imageUrl!.isEmpty)
                      ? const Center(
                          child: Icon(
                            Icons.business,
                            size: 48,
                            color: AppColors.gray400,
                          ),
                        )
                      : null,
                ),
                // Status Badge
                Positioned(
                  top: Dimensions.spaceM,
                  left: Dimensions.spaceM,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(project.status),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      _getStatusText(project.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Project Info
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spaceS),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: Dimensions.spaceXS),
                      Expanded(
                        child: Text(
                          project.locationName ?? project.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceL),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'نسبة الإنجاز',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${completionPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  LinearProgressIndicator(
                    value: completionPercentage / 100,
                    backgroundColor: AppColors.gray200,
                    color: AppColors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),

                  const SizedBox(height: Dimensions.spaceL),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(
                        icon: Icons.apartment,
                        label: 'إجمالي الوحدات',
                        value: '${project.totalUnits}',
                      ),
                      _buildStat(
                        icon: Icons.check_circle,
                        label: 'متاح',
                        value: '$availableUnits',
                        valueColor: AppColors.success,
                      ),
                      _buildStat(
                        icon: Icons.groups,
                        label: 'الشركاء',
                        value: '${project.totalPartners ?? 0}',
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceL),

                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProjectDetailFullScreen(project: project),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('عرض التفاصيل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.spaceM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
