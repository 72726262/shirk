import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/wallet_card.dart';
import 'package:mmm/presentation/widgets/custom/project_card.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_card.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';
import 'package:mmm/presentation/widgets/common/error_widget.dart'
    as error_widgets;
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<DashboardCubit>().loadDashboard(authState.user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          BlocBuilder<DashboardCubit, DashboardState>(
            builder: (context, state) {
              final unreadCount = state is DashboardLoaded
                  ? state.unreadNotificationCount
                  : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, RouteNames.notifications);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.profile);
            },
          ),
        ],
      ),
      body: BlocConsumer<DashboardCubit, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'إعادة المحاولة',
                  textColor: Colors.white,
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is Authenticated) {
                      context.read<DashboardCubit>().loadDashboard(
                        authState.user.id,
                      );
                    }
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DashboardLoading) {
            return _buildLoadingState();
          }

          if (state is DashboardError) {
            return Center(
              child: error_widgets.CustomErrorWidget(
                message: state.message,
                onRetry: () {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is Authenticated) {
                    context.read<DashboardCubit>().loadDashboard(
                      authState.user.id,
                    );
                  }
                },
              ),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<DashboardCubit>().refreshDashboard(
                    authState.user.id,
                  );
                }
              },
              child: _buildContent(state),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: Dimensions.screenPadding,
      children: const [
        SkeletonCard(height: 200),
        SizedBox(height: Dimensions.spaceXXL),
        SkeletonCard(height: 150),
        SizedBox(height: Dimensions.spaceXXL),
        SkeletonList(itemCount: 3),
      ],
    );
  }

  Widget _buildContent(DashboardLoaded state) {
    return SingleChildScrollView(
      padding: Dimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Card
          WalletCard(
            wallet: state.wallet,
            onAddFunds: () {
              Navigator.pushNamed(context, RouteNames.addFunds);
            },
            onWithdraw: () {
              Navigator.pushNamed(context, RouteNames.withdrawFunds);
            },
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // My Projects Section
          _buildSectionHeader('مشاريعي', () {
            Navigator.pushNamed(context, RouteNames.projectsList);
          }),
          const SizedBox(height: Dimensions.spaceL),
          _buildMyProjectsSection(state.myProjects),
          const SizedBox(height: Dimensions.spaceXXL),

          // Quick Stats
          _buildQuickStats(
            totalInvestment: state.totalInvestment,
            activeProjects: state.activeProjects,
            estimatedReturns: state.estimatedReturns,
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // Recent Notifications
          _buildSectionHeader('الإشعارات', () {
            Navigator.pushNamed(context, RouteNames.notifications);
          }),
          const SizedBox(height: Dimensions.spaceL),
          _buildRecentNotifications(
            state.recentNotifications,
            state.unreadNotificationCount,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onViewAll, child: const Text('عرض الكل')),
      ],
    );
  }

  Widget _buildMyProjectsSection(List<ProjectModel> projects) {
    if (projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.spaceXXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: Dimensions.spaceM),
            const Text('لا توجد مشاريع حالياً'),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.projectsList);
              },
              child: const Text('تصفح المشاريع'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(
              left: index == projects.length - 1 ? 0 : Dimensions.spaceM,
            ),
            child: ProjectCard(
              imageUrl:
                  project.imageUrl ?? 'https://via.placeholder.com/300x200',
              title: project.name,
              location: project.location,
              progress: project.completionPercentage ?? 0.0,
              status: _getStatusText(
                project.status,
              ), // تأكد أن هذه الدالة موجودة
              price: '${project.minInvestment} ر.س',
              availableUnits: project.availableUnits ?? 0,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.projectDetail,
                  arguments: project.id,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats({
    required double totalInvestment,
    required int activeProjects,
    required double estimatedReturns,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            label: 'إجمالي الاستثمار',
            value: '${totalInvestment.toStringAsFixed(0)} ر.س',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: _buildStatCard(
            icon: Icons.business,
            label: 'المشاريع النشطة',
            value: '$activeProjects',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money,
            label: 'العائد المتوقع',
            value: '${estimatedReturns.toStringAsFixed(0)} ر.س',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: Dimensions.spaceS),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Dimensions.spaceXS),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications(
    List<NotificationModel> notifications,
    int unreadCount,
  ) {
    if (notifications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.spaceXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
        ),
        child: const Center(child: Text('لا توجد إشعارات')),
      );
    }

    return Column(
      children: notifications
          .take(3)
          .map((notif) => _buildNotificationTile(notif))
          .toList(),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.white
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            _getNotificationIcon(notification.type.name),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.notificationDetail,
            arguments: notification.id,
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.payment;
      case 'project':
        return Icons.construction;
      case 'kyc':
        return Icons.verified_user;
      case 'handover':
        return Icons.home;
      case 'document':
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}د';
    if (diff.inHours > 0) return '${diff.inHours}س';
    if (diff.inMinutes > 0) return '${diff.inMinutes}د';
    return 'الآن';
  }

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
        return 'تم البيع';
      case ProjectStatus.cancelled:
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }
}
