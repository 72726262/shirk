import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Setup Arabic timeago
    timeago.setLocaleMessages('ar', timeago.ArMessages());

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
          size: 24,
        ),
      ),
      child: Material(
        color: notification.isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              border: Border.all(
                color: notification.isRead ? AppColors.border : AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(Dimensions.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: Dimensions.spaceM),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        notification.titleAr ?? notification.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),

                      // Body
                      Text(
                        notification.bodyAr ?? notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimensions.spaceS),

                      // Time
                      Text(
                        timeago.format(notification.createdAt, locale: 'ar'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.payment:
        return AppColors.accent;
      case NotificationType.kyc:
        return AppColors.info;
      case NotificationType.update:
        return AppColors.primary;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.kyc:
        return Icons.verified_user_outlined;
      case NotificationType.document:
        return Icons.description_outlined;
      case NotificationType.handover:
        return Icons.key_outlined;
      case NotificationType.update:
        return Icons.update;
      default:
        return Icons.notifications_outlined;
    }
  }
}
