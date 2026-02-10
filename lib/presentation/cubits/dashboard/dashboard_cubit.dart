import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/services/wallet_service.dart';
import 'package:mmm/data/services/project_service.dart';
import 'package:mmm/data/services/notification_service.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';
import 'package:mmm/data/repositories/project_repository.dart';
import 'package:mmm/data/repositories/notification_repository.dart';

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final WalletModel wallet;
  final double availableBalance;
  final List<ProjectModel> myProjects;
  final List<NotificationModel> recentNotifications;
  final int unreadNotificationCount;
  final Map<String, dynamic> walletStats;

  const DashboardLoaded({
    required this.wallet,
    required this.availableBalance,
    required this.myProjects,
    required this.recentNotifications,
    required this.unreadNotificationCount,
    required this.walletStats,
  });

  @override
  List<Object?> get props => [
        wallet,
        availableBalance,
        myProjects,
        recentNotifications,
        unreadNotificationCount,
        walletStats,
      ];

  double get totalInvestment => walletStats['total_invested'] as double? ?? 0.0;
  int get activeProjects => myProjects.length;
  double get estimatedReturns => walletStats['estimated_returns'] as double? ?? 0.0;
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class DashboardCubit extends Cubit<DashboardState> {
  final WalletService _walletService;
  final ProjectService _projectService;
  final NotificationService _notificationService;

  DashboardCubit({
    WalletRepository? walletRepository,
    ProjectRepository? projectRepository,
    NotificationRepository? notificationRepository,
  })  : _walletService = WalletService(walletRepository: walletRepository),
        _projectService = ProjectService(projectRepository: projectRepository),
        _notificationService =
            NotificationService(notificationRepository: notificationRepository),
        super(DashboardInitial());

  Future<void> loadDashboard(String userId) async {
    emit(DashboardLoading());
    try {
      // Load data from multiple services in parallel
      final results = await Future.wait([
        _walletService.getWalletDashboard(userId),
        _projectService.browseProjects(), // Featured projects
        _notificationService.getNotifications(userId: userId, isRead: false),
        _notificationService.getUnreadCount(userId),
      ]);

      final walletDashboard = results[0] as Map<String, dynamic>;
      final allProjects = results[1] as List<ProjectModel>;
      final notifications = results[2] as List<NotificationModel>;
      final unreadCount = results[3] as int;

      // Get user's active projects (subscriptions)
      // For now, show featured projects
      final myProjects = allProjects.where((p) => p.featured).take(5).toList();

      emit(DashboardLoaded(
        wallet: walletDashboard['wallet'] as WalletModel,
        availableBalance: walletDashboard['available_balance'] as double,
        myProjects: myProjects,
        recentNotifications: notifications.take(5).toList(),
        unreadNotificationCount: unreadCount,
        walletStats: walletDashboard['stats'] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> refreshDashboard(String userId) async {
    await loadDashboard(userId);
  }
}
