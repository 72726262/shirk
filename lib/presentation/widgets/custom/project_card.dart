import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart'; // أضف هذا import

class ProjectCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final double progress;
  final String status;
  final String price;
  final int availableUnits;
  final VoidCallback onTap;

  // Constructor الأساسي
  const ProjectCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.progress,
    required this.status,
    required this.price,
    required this.availableUnits,
    required this.onTap,
  });

  // Constructor من ProjectModel - للتوافق مع الكود القديم
  factory ProjectCard.fromProject({
    Key? key,
    required ProjectModel project,
    required VoidCallback onTap,
  }) {
    return ProjectCard(
      key: key,
      imageUrl: project.imageUrl ?? 'https://via.placeholder.com/300x200',
      title: project.name,
      location: project.location,
      progress: project.completionPercentage ?? 0.0,
      status: _getStatusText(project.status),
      price: '${project.minInvestment} ر.س',
      availableUnits: project.availableUnits ?? 0,
      onTap: onTap,
    );
  }

  // دالة مساعدة لتحويل ProjectStatus إلى نص
  static String _getStatusText(ProjectStatus status) {
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
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Project Image
            Container(
              height: 120, // Reduced from 140 to 120
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusL),
                  topRight: Radius.circular(Dimensions.radiusL),
                ),
                color: AppColors.gray200,
                image: imageUrl.isNotEmpty &&
                        imageUrl != 'file:///' &&
                        imageUrl.startsWith('http')
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image load error silently
                        },
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Status Badge
                  Positioned(
                    top: Dimensions.spaceS, // Reduced from M
                    left: Dimensions.spaceS, // Reduced from M
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceS,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusS,
                        ),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10, // Reduced font size
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Project Details
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceS), // Reduced from M
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Slightly smaller
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: Dimensions.spaceXS),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12, // Smaller icon
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: Dimensions.spaceXS),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceS), // Reduced from M

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التقدم',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10),
                          ),
                          Text(
                            '${progress.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.gray200,
                        color: AppColors.primary,
                        minHeight: 3, // Thinner
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceS), // Reduced from M

                  // Price and Units
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السعر',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 12, // Smaller
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.spaceXS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'الوحدات',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                            ),
                            Text(
                              '$availableUnits وحدة',
                              style: const TextStyle(
                                fontSize: 12, // Smaller
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Dimensions.spaceS), // Reduced from M

                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    height: 32, // Reduced height
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusS,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('عرض التفاصيل',
                          style: TextStyle(fontSize: 11)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد التنفيذ':
        return AppColors.primary;
      case 'مكتمل':
        return AppColors.success;
      case 'قيد الإعداد':
        return AppColors.info;
      case 'متوقف':
        return AppColors.warning;
      case 'مباع بالكامل':
        return AppColors.accent;
      case 'ملغي':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}
