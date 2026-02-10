import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class ProgressTimeline extends StatelessWidget {
  final List<TimelineItem> items;
  final int currentStep;

  const ProgressTimeline({
    super.key,
    required this.items,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isActive = index <= currentStep;
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line and Circle
            Column(
              children: [
                // Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.gray300,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.gray400,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isActive
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                // Line
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: isActive ? AppColors.primary : AppColors.gray300,
                  ),
              ],
            ),

            const SizedBox(width: Dimensions.spaceL),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      item.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                  if (item.date != null) ...[
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      item.date!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                  if (item.description != null) ...[
                    const SizedBox(height: Dimensions.spaceS),
                    Text(
                      item.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class TimelineItem {
  final String title;
  final String? subtitle;
  final String? date;
  final String? description;
  final bool isCompleted;

  TimelineItem({
    required this.title,
    this.subtitle,
    this.date,
    this.description,
    this.isCompleted = false,
  });
}
