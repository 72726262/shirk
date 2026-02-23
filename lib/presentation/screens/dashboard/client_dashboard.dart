import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/widgets/custom/premium_wallet_card.dart';
import 'package:mmm/presentation/widgets/custom/project_card.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_card.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';
import 'package:mmm/presentation/widgets/common/error_widget.dart'
    as error_widgets;

import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/models/installment_model.dart';

import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/chat/chat_list_cubit.dart'; // Added
import 'package:mmm/presentation/widgets/dialogs/kyc_approval_dialog.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _checkKycApprovalStatus(authState.user);
    }
  }

  // ✅ Check if KYC was just approved
  Future<void> _checkKycApprovalStatus(UserModel user) async {
    if (user.kycStatus == KYCStatus.approved) {
      final prefs = await SharedPreferences.getInstance();
      final hasShownApproval =
          prefs.getBool('kyc_approval_shown_${user.id}') ?? false;

      if (!hasShownApproval) {
        // Show approval dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showKycApprovalDialog(context);
            prefs.setBool('kyc_approval_shown_${user.id}', true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
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

            BlocBuilder<ChatListCubit, ChatListState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is ChatListLoaded) {
                  unreadCount = state.totalUnreadCount;
                }
                return Stack(
                  children: [
                    IconButton(
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: const Icon(Icons.chat),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, RouteNames.chatList);
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: Dimensions.screenPadding,
      child: Column(
        children: const [
          SkeletonCard(height: 200),
          SizedBox(height: Dimensions.spaceXXL),
          SkeletonCard(height: 150),
          SizedBox(height: Dimensions.spaceXXL),
          SkeletonList(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardLoaded state) {
    return SingleChildScrollView(
      padding: Dimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium 3D Wallet Card
          Premium3DWalletCard(
            wallet: state.wallet,
            onAddFunds: () {
              Navigator.pushNamed(context, RouteNames.addFunds);
            },
            onWithdraw: () {
              Navigator.pushNamed(context, RouteNames.withdrawFunds);
            },
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // ✅ KYC Status Card
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                return _buildKycStatusCard(authState.user.kycStatus);
              }
              return const SizedBox.shrink();
            },
          ),

          // Overdue Installments Alert
          if (state.hasOverduePayments) ...[
            const SizedBox(height: Dimensions.spaceL),
            _buildOverdueAlert(state.overdueCount, state.totalOverdueAmount),
          ],

          // Unsigned Documents Alert
          if (state.hasUnsignedDocs) ...[
            const SizedBox(height: Dimensions.spaceL),
            _buildUnsignedDocumentsAlert(
              (state.unsignedDocuments ?? []).length,
            ),
          ],

          // Upcoming Installments
          if ((state.upcomingInstallments ?? []).isNotEmpty) ...[
            const SizedBox(height: Dimensions.spaceXXL),
            _buildSectionHeader('الأقساط القادمة', () {
              Navigator.pushNamed(context, RouteNames.installments);
            }),
            const SizedBox(height: Dimensions.spaceM),
            _buildUpcomingInstallments(state.upcomingInstallments ?? []),
          ],
          const SizedBox(height: Dimensions.spaceXXL),

          // My Projects Section
          _buildSectionHeader('استثماراتي', () {
            // Renamed from 'مشاريعي'
            Navigator.pushNamed(
              context,
              RouteNames.subscriptions,
            ); // Navigate to Subscriptions instead of Projects List
          }),
          const SizedBox(height: Dimensions.spaceL),
          _buildMyProjectsSection(state.mySubscriptions),

          // Latest Construction Updates
          if ((state.latestUpdates ?? []).isNotEmpty) ...[
            const SizedBox(height: Dimensions.spaceXXL),
            _buildSectionHeader('آخر تحديثات البناء', () {
              if (state.mySubscriptions.length == 1) {
                 Navigator.pushNamed(
                  context,
                  RouteNames.constructionUpdates,
                  arguments: state.mySubscriptions.first.project?.id,
                );
              } else {
                 Navigator.pushNamed(context, RouteNames.subscriptions);
              }
            }),
            const SizedBox(height: Dimensions.spaceM),
            _buildConstructionUpdates(state.latestUpdates ?? []),
          ],
          const SizedBox(height: Dimensions.spaceXXL),

          // Quick Stats
          _buildQuickStats(
            totalInvestment: state.totalInvestment,
            activeProjects: state.activeProjects,
            estimatedReturns: state.estimatedReturns,
          ),
          const SizedBox(height: Dimensions.spaceXXL),

          // Quick Access to New Sections
          _buildSectionHeader('الأقسام', () {}),
          const SizedBox(height: Dimensions.spaceL),
          _buildQuickAccessGrid(state.mySubscriptions),
          const SizedBox(height: Dimensions.spaceXXL),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(List<SubscriptionModel> subscriptions) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Dimensions.spaceM,
      crossAxisSpacing: Dimensions.spaceM,
      childAspectRatio: 1.5,
      children: [
        _buildQuickAccessCard(
          icon: Icons.business_center,
          title: 'اشتراكاتي',
          color: AppColors.primary,
          onTap: () {
            Navigator.pushNamed(context, RouteNames.subscriptions);
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.description,
          title: 'المستندات',
          color: AppColors.warning,
          onTap: () {
            Navigator.pushNamed(context, RouteNames.documents);
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.construction,
          title: 'تحديثات البناء',
          color: AppColors.success,
          onTap: () {
            if (subscriptions.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ليس لديك مشاريع نشطة حالياً')),
              );
            } else if (subscriptions.length == 1) {
              final project = subscriptions.first.project;
              if (project != null) {
                Navigator.pushNamed(
                  context,
                  RouteNames.constructionUpdates,
                  arguments: project.id,
                );
              }
            } else {
              Navigator.pushNamed(context, RouteNames.subscriptions);
            }
          },
        ),
        _buildQuickAccessCard(
          icon: Icons.receipt_long,
          title: 'المعاملات',
          color: AppColors.info,
          onTap: () {
            Navigator.pushNamed(context, RouteNames.transactions);
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusL),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: Dimensions.spaceS),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildMyProjectsSection(List<SubscriptionModel> subscriptions) {
    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.spaceXXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.key, // Changed icon to represent ownership/unit
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: Dimensions.spaceM),
            const Text('لم تقم بالاستثمار في أي وحدة بعد'),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.projectsList);
              },
              child: const Text('تصفح المشاريع المتاحة'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 380, // Increased height for detailed card
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          final project = subscription.project;
          final unit = subscription.unit;

          if (project == null) return const SizedBox();

          return Container(
            width: 300,
            margin: EdgeInsets.only(
              left: index == subscriptions.length - 1 ? 0 : Dimensions.spaceM,
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.subscriptionDetail,
                  arguments: subscription,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Header
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(Dimensions.radiusL),
                          ),
                          child: Image.network(
                            project.imageUrl ??
                                'https://via.placeholder.com/300x200',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey[200], height: 160),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusS,
                              ),
                            ),
                            child: Text(
                              _getStatusText(project.status),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusS,
                              ),
                            ),
                            child: const Text(
                              'استثماري',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(Dimensions.spaceM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  project.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: Dimensions.spaceL),

                          // Unit Info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الوحدة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '#${unit?.unitNumber ?? 'غير محدد'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'الحالة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    subscription.status ==
                                            SubscriptionStatus.active
                                        ? 'نشط'
                                        : 'قيد الانتظار',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          subscription.status ==
                                              SubscriptionStatus.active
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          // Investment Value
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'قيمة الاستثمار:',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${subscription.investmentAmount.toStringAsFixed(0)} ر.س',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
    final typeColor = notification.type.displayColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.white
            : typeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : typeColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            notification.type.displayIcon,
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (!notification.isRead) ...[
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteNames.notificationDetail,
            arguments: {'notificationId': notification.id},
          );
        },
      ),
    );
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

  // ✅ KYC Status Card
  Widget _buildKycStatusCard(KYCStatus kycStatus) {
    Color cardColor;
    Color statusColor;
    IconData icon;
    String title;
    String message;
    String actionText;
    bool showAction;

    switch (kycStatus) {
      case KYCStatus.pending:
        cardColor = AppColors.warning.withOpacity(0.1);
        statusColor = AppColors.warning;
        icon = Icons.pending_outlined;
        title = 'التحقق من الهوية مطلوب';
        message = 'يرجى إكمال عملية KYC للاستفادة من جميع الميزات';
        actionText = 'ابدأ التحقق';
        showAction = true;
        break;
      case KYCStatus.underReview:
        cardColor = AppColors.info.withOpacity(0.1);
        statusColor = AppColors.info;
        icon = Icons.schedule;
        title = 'طلبك قيد المراجعة';
        message = 'نقوم حالياً بمراجعة مستنداتك';
        actionText = 'عرض الطلب';
        showAction = true;
        break;
      case KYCStatus.approved:
        cardColor = AppColors.success.withOpacity(0.1);
        statusColor = AppColors.success;
        icon = Icons.verified_user;
        title = 'حسابك موثّق ✓';
        message = 'تم التحقق من هويتك بنجاح';
        actionText = '';
        showAction = false;
        break;
      case KYCStatus.rejected:
        cardColor = AppColors.error.withOpacity(0.1);
        statusColor = AppColors.error;
        icon = Icons.error_outline;
        title = 'تم رفض طلبك';
        message = 'يرجى إعادة المحاولة مع تصحيح البيانات';
        actionText = 'إعادة المحاولة';
        showAction = true;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 32),
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showAction)
            Flexible(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.kycVerification);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.spaceM,
                    vertical: Dimensions.spaceS,
                  ),
                ),
                child: Text(actionText),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverdueAlert(int count, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.1),
            AppColors.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber,
              color: AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أقساط متأخرة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لديك $count قسط متأخر بقيمة ${totalAmount.toStringAsFixed(2)} ر.س',
                  style: TextStyle(fontSize: 13, color: AppColors.gray700),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, RouteNames.installments),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('دفع الآن'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsignedDocumentsAlert(int count) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مستندات تحتاج توقيع',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count مستند تحتاج مراجعة وتوقيع',
                  style: TextStyle(fontSize: 13, color: AppColors.gray700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.documents),
            child: const Text('مراجعة'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingInstallments(List<InstallmentModel> installments) {
    final displayInstallments = installments.take(3).toList();
    return Column(
      children: displayInstallments.map((installment) {
        final daysUntilDue = installment.dueDate
            .difference(DateTime.now())
            .inDays;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.info.withOpacity(0.08),
                AppColors.info.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.info,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قسط #${installment.installmentNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$daysUntilDue يوم متبقي',
                      style: TextStyle(color: AppColors.gray600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '${installment.amount.toStringAsFixed(2)} ر.س',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConstructionUpdates(List<ConstructionUpdateModel> updates) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: updates.length,
        itemBuilder: (context, index) {
          final update = updates[index];
          return Container(
            width: 300,
            margin: EdgeInsets.only(
              right: index < updates.length - 1 ? Dimensions.spaceM : 0,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (update.photos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                    child: Image.network(
                      update.photos.first,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppColors.gray200,
                        child: const Icon(
                          Icons.construction,
                          size: 40,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 14,
                            color: AppColors.gray600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(update.updateDate ?? DateTime.now()).day}/${(update.updateDate ?? DateTime.now()).month}/${(update.updateDate ?? DateTime.now()).year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                          const Spacer(),
                          if (update.progressPercentage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${update.progressPercentage!.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
