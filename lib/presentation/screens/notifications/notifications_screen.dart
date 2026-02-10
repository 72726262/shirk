import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/notifications/notifications_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<NotificationsCubit>().loadNotifications(
        authState.user.id,
        isRead: null,
      );
      context.read<NotificationsCubit>().subscribeToNotifications(authState.user.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    context.read<NotificationsCubit>().unsubscribeFromNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.primary,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Authenticated) {
                      context.read<NotificationsCubit>().markAllAsRead(authState.user.id);
                    }
                  },
                  child: const Text(
                    'تحديد الكل كمقروء',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          indicatorColor: AppColors.white,
          onTap: (index) {
            final authState = context.read<AuthCubit>().state;
            if (authState is Authenticated) {
              context.read<NotificationsCubit>().loadNotifications(
                authState.user.id,
                isRead: index == 0 ? null : (index == 1 ? false : true),
              );
            }
          },
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'غير مقروءة'),
          ],
        ),
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is NotificationMarkedAsRead) {
            // Refresh list
            final authState = context.read<AuthCubit>().state;
            if (authState is Authenticated) {
              context.read<NotificationsCubit>().loadNotifications(
                authState.user.id,
                isRead: _tabController.index == 0 ? null : (_tabController.index == 1 ? false : true),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<NotificationsCubit>().refreshNotifications(authState.user.id);
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: Dimensions.spaceM),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: Dimensions.spaceL),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is Authenticated) {
                        context.read<NotificationsCubit>().deleteNotification(authState.user.id, notification.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حذف الإشعار')),
                      );
                    },
                    child: _buildNotificationTile(notification),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Dimensions.spaceL),
          const Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.white
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.spaceXS),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Dimensions.spaceXS),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationsCubit>().markAsRead(
              context.read<AuthCubit>().state is Authenticated 
                ? (context.read<AuthCubit>().state as Authenticated).user.id 
                : '', 
              notification.id
            );
          }
          Navigator.pushNamed(
            context,
            RouteNames.notificationDetail,
            arguments: {'notificationId': notification.id},
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.update: // Assuming Project maps to update or project specific enum if exists
        return Icons.construction;
      case NotificationType.kyc:
        return Icons.verified_user;
      case NotificationType.handover:
        return Icons.home;
      case NotificationType.document:
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
