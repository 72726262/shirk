import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/admin_repository.dart';
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

// ========== UPDATED CUBIT WITH STREAM SUPPORT ==========
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminRepository _adminRepository;
  
  // Stream subscription for real-time updates
  StreamSubscription? _statsSubscription;
  
  // Cache for null-safe fallback
  AdminStats? _cachedStats;

  AdminDashboardCubit({
    AdminRepository? adminRepository,
  })  : _adminRepository = adminRepository ?? AdminRepository(),
        super(AdminDashboardInitial());

  /// Load dashboard with REAL-TIME STREAM support
  void loadDashboard() {
    emit(AdminDashboardLoading());
    
    // Cancel any previous subscription
    _statsSubscription?.cancel();
    
    // Subscribing to dashboard stats stream
    
    // Subscribe to real-time stream
    _statsSubscription = _adminRepository.getDashboardStatsStream().listen(
      (dashboardStats) {
        // Real-time update received
        
        final newStats = AdminStats(
          totalClients: dashboardStats.totalClients,
          activeProjects: dashboardStats.activeProjects,
          totalRevenue: dashboardStats.totalRevenue,
          pendingPayments: dashboardStats.pendingPayments,
        );
        
        // NULL-SAFE FALLBACK LOGIC
        // If new data seems invalid (all zeros) but we have valid cached data, keep the old data
        if (newStats.totalClients == 0 && 
            newStats.activeProjects == 0 &&
            _cachedStats != null && 
            (_cachedStats!.totalClients > 0 || _cachedStats!.activeProjects > 0)) {
          // Skip empty data, keep cached
          return; // Skip this emission, keep showing cached data
        }
        
        // Stats updated silently
        
        // Update cache
        _cachedStats = newStats;
        
        // Cache for offline access
        CacheService().cacheDashboardStats(newStats.toJson());
        
        emit(AdminDashboardLoaded(stats: newStats));
      },
      onError: (error) {
        // Stream error - try cached data
        
        // On error, try to show cached data
        if (_cachedStats != null) {
          print('📦 عرض البيانات المخبأة بسبب الخطأ');
          emit(AdminDashboardLoaded(stats: _cachedStats!));
        } else {
          // Try cache service as last resort
          final cachedStatsJson = CacheService().getCachedDashboardStats();
          if (cachedStatsJson != null) {
            final stats = AdminStats.fromJson(cachedStatsJson);
            _cachedStats = stats;
            emit(AdminDashboardLoaded(stats: stats));
          } else {
            emit(AdminDashboardError(ErrorHandler.getErrorMessage(error)));
          }
        }
      },
    );
  }

  /// Refresh dashboard (same as loadDashboard since we use streams)
  Future<void> refreshDashboard() async {
    loadDashboard();
  }

  @override
  Future<void> close() {
    // CRITICAL: Cancel stream subscription to prevent memory leaks
    _statsSubscription?.cancel();
    return super.close();
  }
}
