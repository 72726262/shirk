import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class WalletRepository {
  final SupabaseService _supabaseService;
  
  WalletRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get wallet by user ID
  Future<WalletModel> getWallet(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select('*')
          .eq('user_id', userId)
          .single();

      return WalletModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل المحفظة: ${e.toString()}');
    }
  }

  // Get wallet with real-time updates
  Stream<WalletModel> watchWallet(String userId) {
    return _client
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => WalletModel.fromJson(data.first));
  }

  // Add funds to wallet
  Future<TransactionModel> addFunds({
    required String userId,
    required double amount,
    required String paymentMethod,
    String? referenceId,
  }) async {
    try {
      // Get wallet
      final wallet = await getWallet(userId);

      // Create transaction
      final transactionData = {
        'wallet_id': wallet.id,
        'user_id': userId,
        'type': 'deposit',
        'amount': amount,
        'status': 'pending',
        'payment_method': paymentMethod,
        'reference_id': referenceId,
        'description': 'إضافة رصيد',
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select('*')
          .single();

      final transaction = TransactionModel.fromJson(response);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Update transaction status to completed
      await _client
          .from('transactions')
          .update({'status': 'completed'})
          .eq('id', transaction.id);

      // Update wallet balance
      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance + amount,
            'total_deposits': wallet.totalDeposits + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      return transaction;
    } catch (e) {
      throw Exception('خطأ في إضافة الرصيد: ${e.toString()}');
    }
  }

  // Withdraw funds from wallet
  Future<TransactionModel> withdrawFunds({
    required String userId,
    required double amount,
    required String iban,
  }) async {
    try {
      // Get wallet
      final wallet = await getWallet(userId);

      // Check balance
      if (wallet.balance < amount) {
        throw Exception('الرصيد غير كافٍ');
      }

      // Create transaction
      final transactionData = {
        'wallet_id': wallet.id,
        'user_id': userId,
        'type': 'withdrawal',
        'amount': amount,
        'status': 'processing',
        'payment_method': 'bank_transfer',
        'description': 'سحب رصيد إلى $iban',
        'metadata': {'iban': iban},
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select('*')
          .single();

      final transaction = TransactionModel.fromJson(response);

      // Update wallet balance immediately
      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance - amount,
            'total_withdrawals': wallet.totalWithdrawals + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      return transaction;
    } catch (e) {
      throw Exception('خطأ في سحب الرصيد: ${e.toString()}');
    }
  }

  // Get transactions with filters
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? type, // deposit, withdrawal, payment
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('transactions')
          .select('*')
          .eq('user_id', userId);

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
      throw Exception('خطأ في تحميل المعاملات: ${e.toString()}');
    }
  }

  // Get transaction by ID
  Future<TransactionModel> getTransactionById(String transactionId) async {
    try {
      final response = await _client
          .from('transactions')
          .select('*')
          .eq('id', transactionId)
          .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل المعاملة: ${e.toString()}');
    }
  }

  // Make payment from wallet
  Future<TransactionModel> makePayment({
    required String userId,
    required double amount,
    required String description,
    String? subscriptionId,
    String? installmentId,
  }) async {
    try {
      // Get wallet
      final wallet = await getWallet(userId);

      // Check balance
      if (wallet.balance < amount) {
        throw Exception('الرصيد غير كافٍ');
      }

      // Create transaction
      final transactionData = {
        'wallet_id': wallet.id,
        'user_id': userId,
        'type': 'payment',
        'amount': amount,
        'status': 'completed',
        'payment_method': 'wallet',
        'description': description,
        'metadata': {
          if (subscriptionId != null) 'subscription_id': subscriptionId,
          if (installmentId != null) 'installment_id': installmentId,
        },
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select('*')
          .single();

      // Update wallet balance
      await _client
          .from('wallets')
          .update({
            'balance': wallet.balance - amount,
            'total_payments': wallet.totalPayments + amount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      return TransactionModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في الدفع: ${e.toString()}');
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    try {
      final wallet = await getWallet(userId);
      final transactions = await getTransactions(userId: userId, limit: 100);

      final deposits = transactions
          .where((t) => t.type == TransactionType.deposit)
          .toList();
      final withdrawals = transactions
          .where((t) => t.type == TransactionType.withdrawal)
          .toList();
      final payments = transactions
          .where((t) => t.type == TransactionType.payment)
          .toList();

      return {
        'balance': wallet.balance,
        'total_deposits': wallet.totalDeposits,
        'total_withdrawals': wallet.totalWithdrawals,
        'total_payments': wallet.totalPayments,
        'deposits_count': deposits.length,
        'withdrawals_count': withdrawals.length,
        'payments_count': payments.length,
        'last_transaction': transactions.isNotEmpty
            ? transactions.first.createdAt
            : null,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات المحفظة: ${e.toString()}');
    }
  }
}
