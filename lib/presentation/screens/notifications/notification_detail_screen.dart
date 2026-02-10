import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/presentation/cubits/notifications/notifications_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<NotificationsCubit>().markAsRead(authState.user.id, widget.notificationId);
    }
    context.read<NotificationsCubit>().loadNotificationDetail(widget.notificationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الإشعار'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationDetailLoaded) {
            final notification = state.notification;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.spaceXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon and Title
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        size: 40,
                        color: _getNotificationColor(notification.type),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Title
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  // Time
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: Dimensions.spaceS),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Content
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceXL),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    child: Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ),
                  
                  if (notification.actionUrl != null) ...[
                    const SizedBox(height: Dimensions.spaceXL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to action URL
                          Navigator.pushNamed(context, notification.actionUrl!);
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('عرض التفاصيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceL),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success: return AppColors.success;
      case NotificationType.warning: return AppColors.warning;
      case NotificationType.error: return AppColors.error;
      default: return AppColors.info;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success: return Icons.check_circle;
      case NotificationType.warning: return Icons.warning;
      case NotificationType.error: return Icons.error;
      case NotificationType.payment: return Icons.payment;
      case NotificationType.update: return Icons.build;
      default: return Icons.notifications;
    }
  }
}

