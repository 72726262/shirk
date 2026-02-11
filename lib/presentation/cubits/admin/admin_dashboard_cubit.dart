import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/admin_repository.dart'; // ✅ استخدام AdminRepository
import 'package:mmm/core/services/cache_service.dart';
import 'package:mmm/core/utils/error_handler.dart';

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

  Map<String, dynamic> toJson() => {
    'totalClients': totalClients,
    'activeProjects': activeProjects,
    'totalRevenue': totalRevenue,
    'pendingPayments': pendingPayments,
  };

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
    totalClients: json['totalClients'] as int,
    activeProjects: json['activeProjects'] as int,
    totalRevenue: (json['totalRevenue'] as num).toDouble(),
    pendingPayments: json['pendingPayments'] as int,
  );

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
  final AdminRepository _adminRepository; // ✅ استخدام AdminRepository

  AdminDashboardCubit({
    AdminRepository? adminRepository,
  })  : _adminRepository = adminRepository ?? AdminRepository(),
        super(AdminDashboardInitial());

  Future<void> loadDashboard() async {
    emit(AdminDashboardLoading());
    try {
      print('📊 جلب إحصائيات Dashboard من Supabase...');
      
      // ✅ جلب البيانات الحقيقية من Supabase
      final dashboardStats = await _adminRepository.getDashboardStats();
      
      final stats = AdminStats(
        totalClients: dashboardStats.totalClients,
        activeProjects: dashboardStats.activeProjects,
        totalRevenue: dashboardStats.totalRevenue,
        pendingPayments: dashboardStats.pendingPayments,
      );

      print('✅ تم جلب الإحصائيات:');
      print('   العملاء: ${stats.totalClients}');
      print('   المشاريع النشطة: ${stats.activeProjects}');
      print('   الإيرادات: ${stats.totalRevenue}');
      print('   المدفوعات المعلقة: ${stats.pendingPayments}');

      // Cache dashboard stats for offline access
      await CacheService().cacheDashboardStats(stats.toJson());

      emit(AdminDashboardLoaded(stats: stats));
    } catch (e) {
      print('❌ خطأ في loadDashboard: $e');
      
      // Try to load from cache when network fails
      final cachedStats = CacheService().getCachedDashboardStats();
      if (cachedStats != null) {
        final stats = AdminStats.fromJson(cachedStats);
        emit(AdminDashboardLoaded(stats: stats));
      } else {
        emit(AdminDashboardError(ErrorHandler.getErrorMessage(e)));
      }
    }
  }

  Future<void> refreshDashboard() => loadDashboard();
}
