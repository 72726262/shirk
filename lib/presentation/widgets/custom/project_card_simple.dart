import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:intl/intl.dart';

/// Alternative ProjectCard that can work with individual parameters
/// for screens that don't have a full ProjectModel available
class ProjectCardSimple extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final double progress;
  final String status;
  final String price;
  final int availableUnits;
  final VoidCallback? onTap;

  const ProjectCardSimple({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.progress,
    required this.status,
    required this.price,
    required this.availableUnits,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Dimensions.cardRadius),
                  ),
                  child: AspectRatio(
                    aspectRatio: Dimensions.aspectRatioProject,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.gray200,
                        child: const Icon(
                          Icons.business,
                          size: 48,
                          color: AppColors.gray400,
                        ),
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: Dimensions.spaceM,
                  right: Dimensions.spaceM,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppColors.white,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: Dimensions.spaceXS),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'نسبة الإنجاز',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${progress.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.gray200,
                        color: AppColors.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  // Price and Units
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'السعر من',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apartment,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: Dimensions.spaceXS),
                            Text(
                              '$availableUnits وحدة متاحة',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'قيد التنفيذ':
        return AppColors.info;
      case 'مكتمل':
        return AppColors.success;
      case 'قيد الإعداد':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
