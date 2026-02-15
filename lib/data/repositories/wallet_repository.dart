import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class WalletRepository {
  final SupabaseService _supabaseService;

  WalletRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  /// Get wallet by user ID (one-time fetch)
  Future<WalletModel> getWallet(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('المحفظة غير موجودة');
      }

      return WalletModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحميل المحفظة: ${e.toString()}');
    }
  }

  /// Watch wallet changes (deprecated - use getWalletStream instead)
  @Deprecated('Use getWalletStream() instead')
  Stream<WalletModel> watchWallet(String userId) {
    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => WalletModel.fromJson(data.first));
  }

  /// Add funds to wallet
  Future<void> addFunds({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceId,
  }) async {
    try {
      final wallet = await getWallet(userId);

      await _client.from('transactions').insert({
        'wallet_id': wallet.id,
        'type': 'deposit',
        'amount': amount,
        'status': 'completed',
        'payment_method': paymentMethod,
        'reference_id': referenceId,
        'description': 'إيداع رصيد',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
    } catch (e) {
      throw Exception('فشل إيداع الرصيد: ${e.toString()}');
    }
  }

  /// Withdraw funds from wallet
  Future<void> withdrawFunds({
    required String userId,
    required double amount,
    required String iban,
  }) async {
    try {
      final wallet = await getWallet(userId);

      if (wallet.balance < amount) {
        throw Exception('الرصيد غير كافي');
      }

      await _client.from('transactions').insert({
        'wallet_id': wallet.id,
        'type': 'withdrawal',
        'amount': amount,
        'status': 'pending',
        'description': 'سحب رصيد',
        'metadata': {'iban': iban},
        'created_at': DateTime.now().toIso8601String(),
      });

      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance - amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
    } catch (e) {
      throw Exception('فشل سحب الرصيد: ${e.toString()}');
    }
  }

  /// Get transactions history
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      final wallet = await getWallet(userId);

      var query = _client
          .from('transactions')
          .select('*')
          .eq('wallet_id', wallet.id);

      if (type != null) {
        query = query.eq('type', type);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('فشل تحميل المعاملات: ${e.toString()}');
    }
  }

  /// Get transaction by ID
  Future<TransactionModel> getTransactionById(String transactionId) async {
    try {
      final response = await _client
          .from('transactions')
          .select('*')
          .eq('id', transactionId)
          .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw Exception('فشل تحميل المعاملة: ${e.toString()}');
    }
  }

  /// Make payment from wallet
  Future<void> makePayment({
    required String userId,
    required double amount,
    required String description,
    String? subscriptionId,
    String? installmentId,
  }) async {
    try {
      final wallet = await getWallet(userId);

      if (wallet.balance < amount) {
        throw Exception('الرصيد غير كافي');
      }

      await _client.from('transactions').insert({
        'wallet_id': wallet.id,
        'type': 'payment',
        'amount': amount,
        'status': 'completed',
        'description': description,
        'metadata': {
          'subscription_id': subscriptionId,
          'installment_id': installmentId,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance - amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
    } catch (e) {
      throw Exception('فشل الدفع: ${e.toString()}');
    }
  }

  /// Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final wallet = await getWallet(userId);
      final transactions = await getTransactions(userId: userId);

      final totalDeposits = transactions
          .where((t) => t.type == 'deposit')
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalWithdrawals = transactions
          .where((t) => t.type == 'withdrawal')
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalPayments = transactions
          .where((t) => t.type == 'payment')
          .fold(0.0, (sum, t) => sum + t.amount);

      return {
        'current_balance': wallet.balance,
        'total_deposits': totalDeposits,
        'total_withdrawals': totalWithdrawals,
        'total_payments': totalPayments,
        'transaction_count': transactions.length,
      };
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المحفظة: ${e.toString()}');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get wallet with real-time updates
  Stream<WalletModel> getWalletStream(String userId) {
    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .map((data) {
          final wallet = data.firstWhere(
            (w) => w['user_id'] == userId,
            orElse: () => throw Exception('المحفظة غير موجودة'),
          );
          return WalletModel.fromJson(wallet);
        });
  }

  /// Get transactions with real-time updates
  Stream<List<TransactionModel>> getTransactionsStream({
    required String userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async* {
    try {
      // First get wallet ID
      final wallet = await getWallet(userId);

      // Stream transactions
      yield* _client
          .from('transactions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) {
        var filtered = data.where((t) => t['wallet_id'] == wallet.id).toList();

        if (type != null) {
          filtered = filtered.where((t) => t['type'] == type).toList();
        }
        if (startDate != null) {
          filtered = filtered.where((t) {
            final createdAt = DateTime.parse(t['created_at']);
            return createdAt.isAfter(startDate) || createdAt.isAtSameMomentAs(startDate);
          }).toList();
        }
        if (endDate != null) {
          filtered = filtered.where((t) {
            final createdAt = DateTime.parse(t['created_at']);
            return createdAt.isBefore(endDate) || createdAt.isAtSameMomentAs(endDate);
          }).toList();
        }

        final limited = filtered.length > limit ? filtered.take(limit).toList() : filtered;
        return limited.map((json) => TransactionModel.fromJson(json)).toList();
      });
    } catch (e) {
      throw Exception('خطأ في البث المباشر للمعاملات: ${e.toString()}');
    }
  }

  /// Get transaction by ID with real-time updates
  Stream<TransactionModel> getTransactionByIdStream(String transactionId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .map((data) {
          final transaction = data.firstWhere(
            (t) => t['id'] == transactionId,
            orElse: () => throw Exception('المعاملة غير موجودة'),
          );
          return TransactionModel.fromJson(transaction);
        });
  }

  /// Get wallet statistics with real-time updates
  Stream<Map<String, dynamic>> getWalletStatsStream(String userId) async* {
    await for (final wallet in getWalletStream(userId)) {
      await for (final transactions in getTransactionsStream(userId: userId)) {
        final totalDeposits = transactions
            .where((t) => t.type == 'deposit')
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalWithdrawals = transactions
            .where((t) => t.type == 'withdrawal')
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalPayments = transactions
            .where((t) => t.type == 'payment')
            .fold(0.0, (sum, t) => sum + t.amount);

        yield {
          'current_balance': wallet.balance,
          'total_deposits': totalDeposits,
          'total_withdrawals': totalWithdrawals,
          'total_payments': totalPayments,
          'transaction_count': transactions.length,
        };
        break; // Only emit once per wallet update
      }
    }
  }
}
