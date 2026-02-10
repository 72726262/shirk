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

// Cubit
class WalletCubit extends Cubit<WalletState> {
  final WalletRepository _walletRepository;

  WalletCubit({WalletRepository? walletRepository})
      : _walletRepository = walletRepository ?? WalletRepository(),
        super(WalletInitial());

  Future<void> loadWallet(String userId) async {
    emit(WalletLoading());
    try {
      final wallet = await _walletRepository.getWallet(userId);
      final transactions = await _walletRepository.getTransactions(
        userId: userId,
        limit: 20,
      );
      emit(WalletLoaded(wallet, transactions));
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

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
      await loadWallet(userId);
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

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
      await loadWallet(userId);
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> loadTransactions({
    required String userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await _walletRepository.getTransactions(
        userId: userId,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );

      if (state is WalletLoaded) {
        final wallet = (state as WalletLoaded).wallet;
        emit(WalletLoaded(wallet, transactions));
      }
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  Future<void> refreshWallet(String userId) async {
    await loadWallet(userId);
  }

  Future<void> refreshTransactions(String userId) async {
    await loadTransactions(userId: userId);
  }



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

  void subscribeToWallet(String userId) {
    _walletRepository.watchWallet(userId).listen((wallet) {
      if (state is WalletLoaded) {
        final transactions = (state as WalletLoaded).transactions;
        emit(WalletLoaded(wallet, transactions));
      }
    });
  }

  void unsubscribeFromWallet() {
    // Dispose subscription if needed
  }

  void subscribeToWalletUpdates(String userId) {
    _walletRepository.watchWallet(userId).listen((wallet) {
      if (state is WalletLoaded) {
        final transactions = (state as WalletLoaded).transactions;
        emit(WalletLoaded(wallet, transactions));
      }
    });
  }
}
