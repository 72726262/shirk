import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/project_repository.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';

// Models
class AdminStats extends Equatable {
  final int totalClients;
  final int activeProjects;
  final double totalRevenue;
  final int pendingPayments;

  const AdminStats({
    required this.totalClients,
    required this.activeProjects,
    required this.totalRevenue,
    required this.pendingPayments,
  });

  @override
  List<Object?> get props => [totalClients, activeProjects, totalRevenue, pendingPayments];
}

// States
abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminStats stats;

  const AdminDashboardLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final ProjectRepository _projectRepository;
  final WalletRepository _walletRepository;

  AdminDashboardCubit({
    ProjectRepository? projectRepository,
    WalletRepository? walletRepository,
  })  : _projectRepository = projectRepository ?? ProjectRepository(),
        _walletRepository = walletRepository ?? WalletRepository(),
        super(AdminDashboardInitial());

  Future<void> loadDashboard() async {
    emit(AdminDashboardLoading());
    try {
      // Fetch real data
      // final projects = await _projectRepository.getProjects();
      // final activeProjects = projects.where((p) => p.status == ProjectStatus.active).length;
      
      // Mock data for now until repositories support aggregation
      await Future.delayed(const Duration(seconds: 1));
      
      final stats = const AdminStats(
        totalClients: 150,
        activeProjects: 12,
        totalRevenue: 5000000.0,
        pendingPayments: 5,
      );

      emit(AdminDashboardLoaded(stats: stats));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> refreshDashboard() => loadDashboard();
}
