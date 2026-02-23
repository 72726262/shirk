import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/presentation/cubits/notifications/notifications_cubit.dart';
import 'package:mmm/presentation/cubits/notifications/notification_detail_cubit.dart'; // Import new cubit
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationDetailCubit()..loadNotificationDetail(notificationId),
      child: const NotificationDetailView(),
    );
  }
}

class NotificationDetailView extends StatefulWidget {
  const NotificationDetailView({super.key});

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  @override
  void initState() {
    super.initState();
    // Mark as read without affecting the detail view state
    // We access the PARENT NotificationsCubit to mark as read in the list
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      // Find the NotificationsCubit from the context (it should be provided above in the widget tree)
      // If not found, we might need to handle it gracefully or rely on the list refresh.
      // Assuming NotificationsCubit is provided gloablly or in the parent route.
      try {
        // We get the notification ID from the cubit's initial load or passed down?
        // Actually we need the ID here. Let's look at how to get it.
        // The parent NotificationDetailScreen passed it to the Cubit.
        // We can't easily access it here without passing it down or getting it from the Cubit state after load.
        //
        // Better approach: Do the marking as read in the parent screen or passed as a parameter.
        // But since we are here, let's wait for the detail to load.
      } catch (e) {
        print('NotificationsCubit not found in context: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل الإشعار'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<NotificationDetailCubit, NotificationDetailState>(
        listener: (context, state) {
           if (state is NotificationDetailLoaded) {
             // Once loaded, we can mark it as read in the background using the global NotificationsCubit
             final authState = context.read<AuthCubit>().state;
             if (authState is Authenticated) {
               context.read<NotificationsCubit>().markAsRead(authState.user.id, state.notification.id);
             }
           }
        },
        builder: (context, state) {
          if (state is NotificationDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationDetailLoaded) {
            final notification = state.notification;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.spaceXXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // ... existing UI code ...
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

          if (state is NotificationDetailError) {
             return Center(child: Text(state.message));
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

