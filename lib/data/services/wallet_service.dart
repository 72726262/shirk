import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';

/// Wallet Service - Handles wallet and transaction business logic
class WalletService {
  final WalletRepository _walletRepository;

  WalletService({WalletRepository? walletRepository})
      : _walletRepository = walletRepository ?? WalletRepository();

  // Get wallet with transaction summary
  Future<Map<String, dynamic>> getWalletDashboard(String userId) async {
    try {
      final wallet = await _walletRepository.getWallet(userId);
      final recentTransactions = await _walletRepository.getTransactions(
        userId: userId,
        limit: 10,
      );
      final stats = await _walletRepository.getWalletStats(userId);

      return {
        'wallet': wallet,
        'recent_transactions': recentTransactions,
        'stats': stats,
        'available_balance': wallet.balance - wallet.reservedBalance,
      };
    } catch (e) {
      throw Exception('فشل تحميل المحفظة: ${e.toString()}');
    }
  }

  // Add funds to wallet
  Future<void> addFunds({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceId,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      await _walletRepository.addFunds(
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceId: referenceId,
      );
    } catch (e) {
      throw Exception('فشل إضافة الرصيد: ${e.toString()}');
    }
  }

  // Withdraw funds from wallet
  Future<void> withdrawFunds({
    required String userId,
    required double amount,
    required String iban,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      // Check available balance
      final wallet = await _walletRepository.getWallet(userId);
      final availableBalance = wallet.balance - wallet.reservedBalance;

      if (amount > availableBalance) {
        throw Exception('الرصيد المتاح غير كافٍ');
      }

      await _walletRepository.withdrawFunds(
        userId: userId,
        amount: amount,
        iban: iban,
      );
    } catch (e) {
      throw Exception('فشل سحب الرصيد: ${e.toString()}');
    }
  }

  // Get transaction history with filters
  Future<List<TransactionModel>> getTransactionHistory({
    required String userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      return await _walletRepository.getTransactions(
        userId: userId,
        type: type,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('فشل تحميل سجل المعاملات: ${e.toString()}');
    }
  }

  // Process payment (internal transaction)
  Future<void> processPayment({
    required String userId,
    required double amount,
    required String description,
    String? relatedEntityId,
  }) async {
    try {
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      // Check available balance
      final wallet = await _walletRepository.getWallet(userId);
      final availableBalance = wallet.balance - wallet.reservedBalance;

      if (amount > availableBalance) {
        throw Exception('الرصيد المتاح غير كافٍ للدفع');
      }

      await _walletRepository.makePayment(
        userId: userId,
        amount: amount,
        description: description,
        // relatedEntityId: relatedEntityId, // Assuming makePayment handles this in metadata if needed
      );
    } catch (e) {
      throw Exception('فشل معالجة الدفع: ${e.toString()}');
    }
  }

  // Real-time wallet balance stream
  Stream<WalletModel> watchWalletBalance(String userId) {
    try {
      return _walletRepository.watchWallet(userId);
    } catch (e) {
      throw Exception('فشل الاشتراك في تحديثات المحفظة: ${e.toString()}');
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      return await _walletRepository.getWalletStats(userId);
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المحفظة: ${e.toString()}');
    }
  }
}
