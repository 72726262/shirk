// lib/data/repositories/installment_repository.dart
import 'package:mmm/data/models/installment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallmentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get installments for a subscription
  Future<List<InstallmentModel>> getInstallmentsBySubscription(
    String subscriptionId,
  ) async {
    try {
      final data = await _client
          .from('installments')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('due_date', ascending: true);

      return (data as List)
          .map((json) => InstallmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch installments: ${e.toString()}');
    }
  }

  /// Get installments for a user (across all subscriptions)
  Future<List<InstallmentModel>> getInstallmentsByUser(String userId) async {
    try {
      final data = await _client
          .from('installments')
          .select()
          .eq('user_id', userId)
          .order('due_date', ascending: true);

      return (data as List)
          .map((json) => InstallmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user installments: ${e.toString()}');
    }
  }

  /// Get a single installment
  Future<InstallmentModel?> getInstallmentById(String id) async {
    try {
      final data = await _client
          .from('installments')
          .select()
          .eq('id', id)
          .maybeSingle();

      return data != null ? InstallmentModel.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch installment: ${e.toString()}');
    }
  }

  /// Pay an installment
  Future<void> payInstallment({
    required String installmentId,
    required String transactionId,
  }) async {
    try {
      await _client.from('installments').update({
        'status': 'paid',
        'paid_at': DateTime.now().toIso8601String(),
        'payment_transaction_id': transactionId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', installmentId);
    } catch (e) {
      throw Exception('Failed to pay installment: ${e.toString()}');
    }
  }

  /// Apply late fee to an installment
  Future<void> applyLateFee({
    required String installmentId,
    required double lateFeeAmount,
  }) async {
    try {
      await _client.from('installments').update({
        'late_fee_amount': lateFeeAmount,
        'late_fee_applied': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', installmentId);
    } catch (e) {
      throw Exception('Failed to apply late fee: ${e.toString()}');
    }
  }

  /// Get overdue installments
  Future<List<InstallmentModel>> getOverdueInstallments(String userId) async {
    try {
      final now = DateTime.now().toIso8601String().split('T')[0];
      final data = await _client
          .from('installments')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .lt('due_date', now)
          .order('due_date', ascending: true);

      return (data as List)
          .map((json) => InstallmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch overdue installments: ${e.toString()}');
    }
  }

  /// Get upcoming installments (next 30 days)
  Future<List<InstallmentModel>> getUpcomingInstallments(String userId) async {
    try {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 30));
      
      final data = await _client
          .from('installments')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .gte('due_date', now.toIso8601String().split('T')[0])
          .lte('due_date', future.toIso8601String().split('T')[0])
          .order('due_date', ascending: true);

      return (data as List)
          .map((json) => InstallmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming installments: ${e.toString()}');
    }
  }

  // ========== REAL-TIME STREAMS ==========

  /// Stream of all user installments
  Stream<List<InstallmentModel>> getUserInstallmentsStream(String userId) {
    return _client
        .from('installments')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('due_date', ascending: true)
        .map((data) =>
            data.map((json) => InstallmentModel.fromJson(json)).toList());
  }

  /// Stream of upcoming installments (next 30 days)
  Stream<List<InstallmentModel>> getUpcomingInstallmentsStream(String userId) async* {
    await for (final installments in getUserInstallmentsStream(userId)) {
      final now = DateTime.now();
      final future = now.add(const Duration(days: 30));
      
      final upcoming = installments
          .where((installment) =>
              installment.status == InstallmentStatus.pending &&
              installment.dueDate.isAfter(now) &&
              installment.dueDate.isBefore(future))
          .toList();
      
      yield upcoming;
    }
  }

  /// Stream of overdue installments
  Stream<List<InstallmentModel>> getOverdueInstallmentsStream(String userId) async* {
    await for (final installments in getUserInstallmentsStream(userId)) {
      final now = DateTime.now();
      
      final overdue = installments
          .where((installment) =>
              installment.status == InstallmentStatus.pending &&
              installment.dueDate.isBefore(now))
          .toList();
      
      yield overdue;
    }
  }

  /// Stream of installment stats
  Stream<Map<String, dynamic>> getInstallmentStatsStream(String userId) async* {
    await for (final installments in getUserInstallmentsStream(userId)) {
      final totalInstallments = installments.length;
      final paidInstallments = installments
          .where((i) => i.status == InstallmentStatus.paid)
          .length;
      final pendingInstallments = installments
          .where((i) => i.status == InstallmentStatus.pending)
          .length;
      final overdueInstallments = installments
          .where((i) =>
              i.status == InstallmentStatus.pending &&
              i.dueDate.isBefore(DateTime.now()))
          .length;
      final totalAmount = installments.fold<double>(
          0, (sum, i) => sum + i.amount);
      final paidAmount = installments
          .where((i) => i.status == InstallmentStatus.paid)
          .fold<double>(0, (sum, i) => sum + i.amount);
      final pendingAmount = installments
          .where((i) => i.status == InstallmentStatus.pending)
          .fold<double>(0, (sum, i) => sum + i.amount);

      yield {
        'total_installments': totalInstallments,
        'paid_installments': paidInstallments,
        'pending_installments': pendingInstallments,
        'overdue_installments': overdueInstallments,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'pending_amount': pendingAmount,
        'completion_percentage':
            totalInstallments > 0 ? (paidInstallments / totalInstallments) * 100 : 0.0,
      };
    }
  }
}
