import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/core/enums/user_role.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/widgets/common/location_button.dart';

class ProjectDetailFullScreen extends StatelessWidget {
  final ProjectModel project;

  const ProjectDetailFullScreen({super.key, required this.project});

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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف مشروع "${project.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectsCubit>().deleteProject(project.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completionPercentage = project.completionPercentage ?? 0.0;
    final availableUnits = project.availableUnits ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                project.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  project.imageUrl != null
                      ? Image.network(project.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.gray300,
                          child: const Icon(
                            Icons.business,
                            size: 80,
                            color: AppColors.gray500,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 60,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status),
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        _getStatusText(project.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary),
                      const SizedBox(width: Dimensions.spaceS),
                      Expanded(
                        child: Text(
                          project.locationName ?? project.location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Stats Grid
                  _buildStatsGrid(),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Progress Section
                  _buildProgressSection(completionPercentage),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Details Section
                  _buildDetailsSection(),

                  const SizedBox(height: Dimensions.spaceXL),

                  // Location Button
                  if (project.locationLat != null &&
                      project.locationLng != null)
                    LocationButton(
                      locationName: project.locationName ?? project.location,
                      latitude: project.locationLat,
                      longitude: project.locationLng,
                      projectName: project.name,
                    ),

                  const SizedBox(height: Dimensions.spaceL),

                  // Admin Controls
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is! Authenticated) {
                        return const SizedBox.shrink();
                      }

                      final user = authState.user;
                      if (user.role != UserRole.admin) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          // Edit Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to edit screen
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('صفحة التعديل قيد التطوير'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('تعديل المشروع'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
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
                          const SizedBox(height: Dimensions.spaceM),

                          // Delete Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showDeleteConfirmation(context),
                              icon: const Icon(Icons.delete),
                              label: const Text('حذف المشروع'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
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
                      );
                    },
                  ),

                  const SizedBox(height: Dimensions.spaceXXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.apartment,
                  label: 'إجمالي الوحدات',
                  value: '${project.totalUnits}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'الوحدات المتاحة',
                  value: '${project.availableUnits ?? 0}',
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(height: Dimensions.spaceXL),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.groups,
                  label: 'عدد الشركاء',
                  value: '${project.totalPartners ?? 0}',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'سعر المتر',
                  value: '${project.pricePerSqm} ر.س',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primary),
        const SizedBox(height: Dimensions.spaceS),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(double percentage) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نسبة الإنجاز',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceM),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: AppColors.gray200,
            color: AppColors.primary,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: Dimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% مكتمل',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(100 - percentage).toStringAsFixed(0)}% متبقي',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تفاصيل الاستثمار',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),
          _buildDetailRow(
            'الحد الأدنى للاستثمار',
            '${project.minInvestment} ر.س',
          ),
          _buildDetailRow(
            'الحد الأقصى للاستثمار',
            '${project.maxInvestment} ر.س',
          ),
          _buildDetailRow('سعر المتر المربع', '${project.pricePerSqm} ر.س'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
