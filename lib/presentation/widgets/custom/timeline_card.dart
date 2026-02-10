import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TimelineCard extends StatelessWidget {
  final ConstructionUpdateModel update;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;

  const TimelineCard({
    super.key,
    required this.update,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMMM yyyy', 'ar');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Top Line (hide if first)
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 20,
                    color: _getTypeColor().withOpacity(0.3),
                  ),

                // Circle with Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getTypeColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getTypeColor().withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(_getTypeIcon(), color: AppColors.white, size: 20),
                ),

                // Bottom Line (hide if last)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _getTypeColor().withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: Dimensions.spaceL),

          // Content Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Dimensions.spaceXL),
              child: Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                elevation: 2,
                shadowColor: AppColors.shadow,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.spaceM,
                                vertical: Dimensions.spaceXS,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor().withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusM,
                                ),
                              ),
                              child: Text(
                                update.type.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTypeColor(),
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Date
                            Text(
                              dateFormatter.format(update.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textHint),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceM),

                        // Title
                        Text(
                          update.displayTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        if (update.displayDescription != null) ...[
                          const SizedBox(height: Dimensions.spaceS),
                          Text(
                            update.displayDescription!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Progress Percentage
                        if (update.progressPercentage != null) ...[
                          const SizedBox(height: Dimensions.spaceL),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusM,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: update.progressPercentage! / 100,
                                    backgroundColor: AppColors.gray200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getTypeColor(),
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Dimensions.spaceM),
                              Text(
                                '${update.progressPercentage!.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getTypeColor(),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Photos Preview
                        if (update.photos.isNotEmpty) ...[
                          const SizedBox(height: Dimensions.spaceL),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: update.photos.length > 4
                                  ? 4
                                  : update.photos.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: Dimensions.spaceM),
                              itemBuilder: (context, index) {
                                if (index == 3 && update.photos.length > 4) {
                                  return _buildMorePhotosIndicator(
                                    update.photos.length - 3,
                                    update.photos[index],
                                  );
                                }
                                return _buildPhotoThumbnail(
                                  update.photos[index],
                                );
                              },
                            ),
                          ),
                        ],

                        // Report Link
                        if (update.reportUrl != null) ...[
                          const SizedBox(height: Dimensions.spaceL),
                          InkWell(
                            onTap: () {
                              // TODO: Open report
                            },
                            child: Container(
                              padding: const EdgeInsets.all(Dimensions.spaceM),
                              decoration: BoxDecoration(
                                color: AppColors.gray500,
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: Dimensions.spaceS),
                                  Text(
                                    'تقرير مفصل',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.spaceXS),
                                  Icon(
                                    Icons.arrow_back_ios,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusM),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.gray200),
        errorWidget: (context, url, error) =>
            Container(color: AppColors.gray200, child: const Icon(Icons.error)),
      ),
    );
  }

  Widget _buildMorePhotosIndicator(int count, String backgroundUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusM),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: backgroundUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
            child: Center(
              child: Text(
                '+$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (update.type) {
      case UpdateType.milestone:
        return AppColors.success;
      case UpdateType.delay:
        return AppColors.warning;
      case UpdateType.completion:
        return AppColors.accent;
      case UpdateType.progress:
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (update.type) {
      case UpdateType.milestone:
        return Icons.flag;
      case UpdateType.delay:
        return Icons.warning;
      case UpdateType.completion:
        return Icons.check_circle;
      case UpdateType.progress:
      default:
        return Icons.construction;
    }
  }
}
