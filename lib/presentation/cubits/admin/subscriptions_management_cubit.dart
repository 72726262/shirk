import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';

// States
abstract class SubscriptionsManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionsManagementInitial extends SubscriptionsManagementState {}

class SubscriptionsManagementLoading extends SubscriptionsManagementState {}

class SubscriptionsManagementLoaded extends SubscriptionsManagementState {
  final List<SubscriptionModel> allSubscriptions;
  final List<SubscriptionModel> pendingSubscriptions;
  final String
  filterStatus; // 'all', 'pending', 'active', 'completed', 'cancelled'

  SubscriptionsManagementLoaded({
    required this.allSubscriptions,
    required this.pendingSubscriptions,
    this.filterStatus = 'all',
  });

  List<SubscriptionModel> get filteredSubscriptions {
    switch (filterStatus) {
      case 'pending':
        return allSubscriptions
            .where((s) => s.status == SubscriptionStatus.pending)
            .toList();
      case 'active':
        return allSubscriptions
            .where((s) => s.status == SubscriptionStatus.active)
            .toList();
      case 'completed':
        return allSubscriptions
            .where((s) => s.status == SubscriptionStatus.completed)
            .toList();
      case 'cancelled':
        return allSubscriptions
            .where((s) => s.status == SubscriptionStatus.cancelled)
            .toList();
      default:
        return allSubscriptions;
    }
  }

  int get pendingCount => pendingSubscriptions.length;

  @override
  List<Object?> get props => [
    allSubscriptions,
    pendingSubscriptions,
    filterStatus,
  ];

  SubscriptionsManagementLoaded copyWith({
    List<SubscriptionModel>? allSubscriptions,
    List<SubscriptionModel>? pendingSubscriptions,
    String? filterStatus,
  }) {
    return SubscriptionsManagementLoaded(
      allSubscriptions: allSubscriptions ?? this.allSubscriptions,
      pendingSubscriptions: pendingSubscriptions ?? this.pendingSubscriptions,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

class SubscriptionsManagementError extends SubscriptionsManagementState {
  final String message;

  SubscriptionsManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SubscriptionsManagementCubit extends Cubit<SubscriptionsManagementState> {
  final SubscriptionRepository _subscriptionRepository;
  StreamSubscription? _subscriptionsSubscription;
  StreamSubscription? _pendingSubscription;

  SubscriptionsManagementCubit({
    required SubscriptionRepository subscriptionRepository,
  }) : _subscriptionRepository = subscriptionRepository,
       super(SubscriptionsManagementInitial());

  void loadSubscriptions() {
    try {
      emit(SubscriptionsManagementLoading());

      _subscriptionsSubscription?.cancel();
      _pendingSubscription?.cancel();

      // Listen to all subscriptions
      _subscriptionsSubscription = _subscriptionRepository
          .getAllSubscriptionsStream()
          .listen(
            (allSubs) {
              // Also get pending separately for badge
              _pendingSubscription = _subscriptionRepository
                  .getPendingSubscriptionsStream()
                  .listen(
                    (pendingSubs) {
                      if (state is SubscriptionsManagementLoaded) {
                        final currentState =
                            state as SubscriptionsManagementLoaded;
                        emit(
                          currentState.copyWith(
                            allSubscriptions: allSubs,
                            pendingSubscriptions: pendingSubs,
                          ),
                        );
                      } else {
                        emit(
                          SubscriptionsManagementLoaded(
                            allSubscriptions: allSubs,
                            pendingSubscriptions: pendingSubs,
                          ),
                        );
                      }
                    },
                    onError: (error) {
                      emit(SubscriptionsManagementError(error.toString()));
                    },
                  );
            },
            onError: (error) {
              emit(SubscriptionsManagementError(error.toString()));
            },
          );
    } catch (e) {
      emit(SubscriptionsManagementError(e.toString()));
    }
  }

  void changeFilter(String filterStatus) {
    if (state is SubscriptionsManagementLoaded) {
      final currentState = state as SubscriptionsManagementLoaded;
      emit(currentState.copyWith(filterStatus: filterStatus));
    }
  }

  Future<void> approveSubscription(String subscriptionId) async {
    try {
      await _subscriptionRepository.approveSubscription(subscriptionId);
      // TODO: Send notification to user
    } catch (e) {
      emit(SubscriptionsManagementError('Failed to approve: ${e.toString()}'));
      // Reload after error
      loadSubscriptions();
    }
  }

  Future<void> rejectSubscription(String subscriptionId, String? reason) async {
    try {
      await _subscriptionRepository.rejectSubscription(subscriptionId, reason);
      // TODO: Send notification to user with reason
    } catch (e) {
      emit(SubscriptionsManagementError('Failed to reject: ${e.toString()}'));
      // Reload after error
      loadSubscriptions();
    }
  }

  @override
  Future<void> close() {
    _subscriptionsSubscription?.cancel();
    _pendingSubscription?.cancel();
    return super.close();
  }
}
