import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';

// States
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletModel wallet;
  final List<TransactionModel> transactions;

  const WalletLoaded(this.wallet, this.transactions);

  @override
  List<Object?> get props => [wallet, transactions];
}

class TransactionProcessing extends WalletState {
  final String message;

  const TransactionProcessing(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletTransactionCreated extends WalletState {
  final TransactionModel transaction;

  const WalletTransactionCreated(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class WalletError extends WalletState {
  final String message;

  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}

// ========== UPDATED CUBIT WITH STREAM SUPPORT ==========
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _walletRepository;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<WalletModel>? _walletSubscription;
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;
  
  // Cache for null-safe fallback
  WalletModel? _cachedWallet;
  List<TransactionModel>? _cachedTransactions;

  WalletCubit({WalletRepository? walletRepository})
      : _walletRepository = walletRepository ?? WalletRepository(),
        super(WalletInitial());

  /// Load wallet with REAL-TIME STREAM support
  void loadWallet(String userId) {
    emit(WalletLoading());
    
    // Cancel previous subscriptions
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    
    print('💰 الاشتراك في البث المباشر للمحفظة...');
    
    // Subscribe to wallet stream
    _walletSubscription = _walletRepository.getWalletStream(userId).listen(
      (wallet) {
        print('🔄 تحديث المحفظة: ${wallet.balance} ريال');
        _cachedWallet = wallet;
        
        // If we have transactions, emit complete state
        if (_cachedTransactions != null) {
          emit(WalletLoaded(wallet, _cachedTransactions!));
        }
      },
      onError: (error) {
        print('❌ خطأ في البث المباشر للمحفظة: $error');
        if (_cachedWallet != null && _cachedTransactions != null) {
          emit(WalletLoaded(_cachedWallet!, _cachedTransactions!));
        } else {
          emit(WalletError(error.toString()));
        }
      },
    );
    
    // Subscribe to transactions stream
    _transactionsSubscription = _walletRepository.getTransactionsStream(
      userId: userId,
      limit: 20,
    ).listen(
      (transactions) {
        print('🔄 تحديث المعاملات: ${transactions.length}');
        
        // NULL-SAFE FALLBACK
        if (transactions.isEmpty && _cachedTransactions != null && _cachedTransactions!.isNotEmpty) {
          print('⚠️ القائمة فارغة، الاحتفاظ بالبيانات المخبأة');
          return;
        }
        
        _cachedTransactions = transactions;
        
        // If we have wallet, emit complete state
        if (_cachedWallet != null) {
          emit(WalletLoaded(_cachedWallet!, transactions));
        }
      },
      onError: (error) {
        print('❌ خطأ في البث المباشر للمعاملات: $error');
        if (_cachedWallet != null && _cachedTransactions != null) {
          emit(WalletLoaded(_cachedWallet!, _cachedTransactions!));
        }
      },
    );
  }

  /// Add funds (write operation - still uses Future)
  Future<void> addFunds({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceId,
  }) async {
    emit(const TransactionProcessing('جاري إضافة الرصيد...'));
    try {
      await _walletRepository.addFunds(
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceId: referenceId,
      );
      // No need to reload - stream will auto-update!
      print('✅ تمت إضافة الرصيد - سيتم التحديث تلقائياً');
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  /// Withdraw funds (write operation - still uses Future)
  Future<void> withdrawFunds({
    required String userId,
    required double amount,
    required String iban,
  }) async {
    emit(const TransactionProcessing('جاري سحب الرصيد...'));
    try {
      await _walletRepository.withdrawFunds(
        userId: userId,
        amount: amount,
        iban: iban,
      );
      // No need to reload - stream will auto-update!
      print('✅ تم سحب الرصيد - سيتم التحديث تلقائياً');
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  /// Load transactions with filters
  void loadTransactions({
    required String userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _transactionsSubscription?.cancel();
    
    _transactionsSubscription = _walletRepository.getTransactionsStream(
      userId: userId,
      type: type,
      startDate: startDate,
      endDate: endDate,
    ).listen(
      (transactions) {
        _cachedTransactions = transactions;
        if (_cachedWallet != null) {
          emit(WalletLoaded(_cachedWallet!, transactions));
        }
      },
      onError: (error) {
        if (_cachedWallet != null && _cachedTransactions != null) {
          emit(WalletLoaded(_cachedWallet!, _cachedTransactions!));
        } else {
          emit(WalletError(error.toString()));
        }
      },
    );
  }

  /// Refresh (same as load since we use streams)
  Future<void> refreshWallet(String userId) async {
    loadWallet(userId);
  }

  Future<void> refreshTransactions(String userId) async {
    loadTransactions(userId: userId);
  }

  /// Aliases for backward compatibility
  Future<void> createDeposit({
    required String userId,
    required double amount,
    required String paymentMethod,
  }) async {
    await addFunds(userId: userId, amount: amount, paymentMethod: paymentMethod);
  }

  Future<void> createWithdrawal({
    required String userId,
    required double amount,
    required String iban,
  }) async {
    await withdrawFunds(userId: userId, amount: amount, iban: iban);
  }

  @override
  Future<void> close() {
    // CRITICAL: Cancel all subscriptions to prevent memory leaks
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
