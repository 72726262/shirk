import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/notification_model.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';
import 'package:mmm/data/repositories/project_repository.dart';
import 'package:mmm/data/repositories/notification_repository.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/data/repositories/installment_repository.dart';
import 'package:mmm/data/repositories/document_repository.dart';
import 'package:mmm/data/repositories/construction_repository.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:mmm/data/models/construction_update_model.dart';

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
  final List<ProjectModel> featuredProjects;
  final List<SubscriptionModel> mySubscriptions;
  final List<NotificationModel> recentNotifications;
  final int unreadNotificationCount;
  final Map<String, dynamic> stats;
  // New fields for dashboard enhancement (nullable to handle initial state)
  final List<InstallmentModel>? upcomingInstallments;
  final List<InstallmentModel>? overdueInstallments;
  final List<DocumentModel>? unsignedDocuments;
  final List<ConstructionUpdateModel>? latestUpdates;

  const DashboardLoaded({
    required this.wallet,
    required this.featuredProjects,
    required this.mySubscriptions,
    required this.recentNotifications,
    required this.unreadNotificationCount,
    required this.stats,
    this.upcomingInstallments,
    this.overdueInstallments,
    this.unsignedDocuments,
    this.latestUpdates,
  });

  @override
  List<Object?> get props => [
        wallet,
        featuredProjects,
        mySubscriptions,
        recentNotifications,
        unreadNotificationCount,
        stats,
        upcomingInstallments,
        overdueInstallments,
        unsignedDocuments,
        latestUpdates,
      ];

  double get availableBalance => wallet.balance;
  double get totalInvestment => stats['total_invested'] as double? ?? 0.0;
  int get activeProjects => mySubscriptions.length;
  List<ProjectModel> get myProjects => featuredProjects;
  double get estimatedReturns => stats['estimated_returns'] as double? ?? 0.0;
  // Null-safe getters for new dashboard features
  bool get hasOverduePayments => (overdueInstallments ?? []).isNotEmpty;
  bool get hasUnsignedDocs => (unsignedDocuments ?? []).isNotEmpty;
  double get totalOverdueAmount => (overdueInstallments ?? []).fold(0.0, (sum, i) => sum + i.amount);
  int get overdueCount => (overdueInstallments ?? []).length;
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== UPDATED CUBIT WITH STREAM SUPPORT ==========
class DashboardCubit extends Cubit<DashboardState> {
  final WalletRepository _walletRepository;
  final ProjectRepository _projectRepository;
  final NotificationRepository _notificationRepository;
  final SubscriptionRepository _subscriptionRepository;
  final InstallmentRepository _installmentRepository;
  final DocumentRepository _documentRepository;
  final ConstructionRepository _constructionRepository;

  // Stream subscriptions
  StreamSubscription<WalletModel>? _walletSubscription;
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;
  StreamSubscription<List<SubscriptionModel>>? _subscriptionsSubscription;
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<List<InstallmentModel>>? _upcomingInstallmentsSubscription;
  StreamSubscription<List<InstallmentModel>>? _overdueInstallmentsSubscription;
  StreamSubscription<List<DocumentModel>>? _documentsSubscription;
  StreamSubscription<List<ConstructionUpdateModel>>? _constructionUpdatesSubscription;
  
  // Cache for null-safe fallback
  WalletModel? _cachedWallet;
  List<ProjectModel>? _cachedProjects;
  List<SubscriptionModel>? _cachedSubscriptions;
  List<NotificationModel>? _cachedNotifications;
  List<InstallmentModel>? _cachedUpcomingInstallments;
  List<InstallmentModel>? _cachedOverdueInstallments;
  List<DocumentModel>? _cachedUnsignedDocuments;
  List<ConstructionUpdateModel>? _cachedConstructionUpdates;
  int _cachedUnreadCount = 0;
  Map<String, dynamic> _cachedStats = {};

  DashboardCubit({
    WalletRepository? walletRepository,
    ProjectRepository? projectRepository,
    NotificationRepository? notificationRepository,
    SubscriptionRepository? subscriptionRepository,
    InstallmentRepository? installmentRepository,
    DocumentRepository? documentRepository,
    ConstructionRepository? constructionRepository,
  })  : _walletRepository = walletRepository ?? WalletRepository(),
        _projectRepository = projectRepository ?? ProjectRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository(),
        _subscriptionRepository = subscriptionRepository ?? SubscriptionRepository(),
        _installmentRepository = installmentRepository ?? InstallmentRepository(),
        _documentRepository = documentRepository ?? DocumentRepository(),
        _constructionRepository = constructionRepository ?? ConstructionRepository(),
        super(DashboardInitial());

  /// Load dashboard with REAL-TIME STREAMS
  void loadDashboard(String userId) {
    emit(DashboardLoading());
    
    // Cancel previous subscriptions
    _walletSubscription?.cancel();
    _projectsSubscription?.cancel();
    _subscriptionsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _upcomingInstallmentsSubscription?.cancel();
    _overdueInstallmentsSubscription?.cancel();
    _documentsSubscription?.cancel();
    _constructionUpdatesSubscription?.cancel();
    
    print('📊 الاشتراك في البث المباشر للـ Dashboard...');
    
    // Subscribe to wallet stream
    _walletSubscription = _walletRepository.getWalletStream(userId).listen(
      (wallet) {
        print('💰 تحديث المحفظة');
        _cachedWallet = wallet;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في المحفظة: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to featured projects stream
    _projectsSubscription = _projectRepository.getFeaturedProjectsStream().listen(
      (projects) {
        print('🏗️ تحديث المشاريع المميزة: ${projects.length}');
        if (projects.isEmpty && _cachedProjects != null && _cachedProjects!.isNotEmpty) {
          return; // Keep cached data
        }
        _cachedProjects = projects;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في المشاريع: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to user subscriptions stream
    _subscriptionsSubscription = _subscriptionRepository.getUserSubscriptionsStream(userId).listen(
      (subscriptions) {
        print('📝 تحديث الاشتراكات: ${subscriptions.length}');
        if (subscriptions.isEmpty && _cachedSubscriptions != null && _cachedSubscriptions!.isNotEmpty) {
          return; // Keep cached data
        }
        _cachedSubscriptions = subscriptions;
        
        // Calculate stats
        _cachedStats = {
          'total_invested': subscriptions.fold(0.0, (sum, s) => sum + s.investmentAmount),
          'active_subscriptions': subscriptions.where((s) => s.status == SubscriptionStatus.active).length,
        };
        
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في الاشتراكات: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to notifications stream
    _notificationsSubscription = _notificationRepository.getNotificationsStream(
      userId: userId,
      limit: 5,
    ).listen(
      (notifications) {
        print('🔔 تحديث الإشعارات: ${notifications.length}');
        if (notifications.isEmpty && _cachedNotifications != null && _cachedNotifications!.isNotEmpty) {
          return; // Keep cached data
        }
        _cachedNotifications = notifications;
        _cachedUnreadCount = notifications.where((n) => !n.isRead).length;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في الإشعارات: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to upcoming installments stream
    _upcomingInstallmentsSubscription = _installmentRepository.getUpcomingInstallmentsStream(userId).listen(
      (installments) {
        print('📅 تحديث الأقساط القادمة: ${installments.length}');
        if (installments.isEmpty && _cachedUpcomingInstallments != null && _cachedUpcomingInstallments!.isNotEmpty) {
          return;
        }
        _cachedUpcomingInstallments = installments;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في الأقساط القادمة: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to overdue installments stream
    _overdueInstallmentsSubscription = _installmentRepository.getOverdueInstallmentsStream(userId).listen(
      (installments) {
        print('⚠️ تحديث الأقساط المتأخرة: ${installments.length}');
        if (installments.isEmpty && _cachedOverdueInstallments != null && _cachedOverdueInstallments!.isNotEmpty) {
          return;
        }
        _cachedOverdueInstallments = installments;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في الأقساط المتأخرة: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to unsigned documents stream
    _documentsSubscription = _documentRepository.getUserDocumentsStream(userId).listen(
      (documents) {
        final unsigned = documents.where((d) => !d.isSigned && d.requiresSignature).toList();
        print('📄 تحديث المستندات غير الموقعة: ${unsigned.length}');
        if (unsigned.isEmpty && _cachedUnsignedDocuments != null && _cachedUnsignedDocuments!.isNotEmpty) {
          return;
        }
        _cachedUnsignedDocuments = unsigned;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في المستندات: $error');
        _emitDashboardIfReady();
      },
    );
    
    // Subscribe to construction updates for user's subscribed projects
    _constructionUpdatesSubscription = _subscriptionRepository.getUserSubscriptionsStream(userId).asyncExpand((subscriptions) async* {
      if (subscriptions.isEmpty) {
        yield <ConstructionUpdateModel>[];
        return;
      }
      
      // Get latest updates from all subscribed projects
      final allUpdates = <ConstructionUpdateModel>[];
      for (final subscription in subscriptions) {
        try {
          final latest = await _constructionRepository.getLatestUpdate(subscription.projectId);
          if (latest != null) {
            allUpdates.add(latest);
          }
        } catch (e) {
          print('خطأ في تحديثات المشروع ${subscription.projectId}: $e');
        }
      }
      
      // Sort by date (handle nullable DateTime)
      allUpdates.sort((a, b) {
        final dateA = a.updateDate ?? DateTime(2000);
        final dateB = b.updateDate ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
      yield allUpdates.take(5).toList(); // Latest 5 updates
    }).listen(
      (updates) {
        print('🏗️ تحديث البناء: ${updates.length}');
        if (updates.isEmpty && _cachedConstructionUpdates != null && _cachedConstructionUpdates!.isNotEmpty) {
          return;
        }
        _cachedConstructionUpdates = updates;
        _emitDashboardIfReady();
      },
      onError: (error) {
        print('❌ خطأ في تحديثات البناء: $error');
        _emitDashboardIfReady();
      },
    );
  }

  /// Emit dashboard state if all required data is ready
  void _emitDashboardIfReady() {
    if (_cachedWallet != null) {
      emit(DashboardLoaded(
        wallet: _cachedWallet!,
        featuredProjects: _cachedProjects ?? [],
        mySubscriptions: _cachedSubscriptions ?? [],
        recentNotifications: _cachedNotifications ?? [],
        unreadNotificationCount: _cachedUnreadCount,
        stats: _cachedStats,
        upcomingInstallments: _cachedUpcomingInstallments ?? [],
        overdueInstallments: _cachedOverdueInstallments ?? [],
        unsignedDocuments: _cachedUnsignedDocuments ?? [],
        latestUpdates: _cachedConstructionUpdates ?? [],
      ));
    }
  }

  /// Refresh dashboard (same as load since we use streams)
  Future<void> refreshDashboard(String userId) async {
    loadDashboard(userId);
  }

  @override
  Future<void> close() {
    // CRITICAL: Cancel all subscriptions to prevent memory leaks
    _walletSubscription?.cancel();
    _projectsSubscription?.cancel();
    _subscriptionsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _upcomingInstallmentsSubscription?.cancel();
    _overdueInstallmentsSubscription?.cancel();
    _documentsSubscription?.cancel();
    _constructionUpdatesSubscription?.cancel();
    return super.close();
  }
}
