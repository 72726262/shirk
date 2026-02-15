import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class SubscriptionRepository {
  final SupabaseService _supabaseService;
  
  SubscriptionRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // ========== FUTURE-BASED METHODS (Original) ==========

  Future<List<SubscriptionModel>> getUserSubscriptions(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select('*, projects(*), units(*)')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      return (response as List)
          .map((json) => SubscriptionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل الاشتراكات: ${e.toString()}');
    }
  }

  Future<List<SubscriptionModel>> getSubscriptionsByUser(String userId) =>
      getUserSubscriptions(userId);

  Future<SubscriptionModel> getSubscriptionById(String subscriptionId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select('*, projects(*), units(*)')
          .eq('id', subscriptionId)
          .single();

      return SubscriptionModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في تحميل الاشتراك: ${e.toString()}');
    }
  }

  Future<SubscriptionModel> createSubscription({
    required String userId,
    required String projectId,
    String? unitId,
    required double investmentAmount,
    double? ownershipPercentage,
    double? downPayment,
    int? installmentsCount,
  }) async {
    try {
      final subscriptionData = {
        'user_id': userId,
        'project_id': projectId,
        'unit_id': unitId,
        'investment_amount': investmentAmount,
        'ownership_percentage': ownershipPercentage,
        'status': 'pending',
        'down_payment': downPayment,
        'installments_count': installmentsCount ?? 0,
        'installments_paid': 0,
        'joined_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('subscriptions')
          .insert(subscriptionData)
          .select('*, projects(*), units(*)')
          .single();

      return SubscriptionModel.fromJson(response);
    } catch (e) {
      throw Exception('خطأ في إنشاء الاشتراك: ${e.toString()}');
    }
  }

  Future<void> updateSubscriptionStatus({
    required String subscriptionId,
    required SubscriptionStatus status,
  }) async {
    try {
      await _client
          .from('subscriptions')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
    } catch (e) {
      throw Exception('خطأ في تحديث حالة الاشتراك: ${e.toString()}');
    }
  }

  Future<void> signContract({
    required String subscriptionId,
    required String signatureUrl,
  }) async {
    try {
      await _client
          .from('subscriptions')
          .update({
            'contract_signed_at': DateTime.now().toIso8601String(),
            'contract_signature_url': signatureUrl,
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId);
    } catch (e) {
      throw Exception('خطأ في توقيع العقد: ${e.toString()}');
    }
  }

  Future<String> uploadSignature({
    required String subscriptionId,
    required String signatureData,
  }) async {
    try {
      final signatureUrl = await _supabaseService.uploadFile(
        bucketName: 'signatures',
        path: 'subscriptions/$subscriptionId/signature_${DateTime.now().millisecondsSinceEpoch}.png',
        filePath: signatureData,
      );

      return signatureUrl;
    } catch (e) {
      throw Exception('خطأ في رفع التوقيع: ${e.toString()}');
    }
  }

  Future<List<InstallmentModel>> getInstallments(String subscriptionId) async {
    try {
      final response = await _client
          .from('installments')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('installment_number');

      return (response as List)
          .map((json) => InstallmentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('خطأ في تحميل الأقساط: ${e.toString()}');
    }
  }

  Future<void> payInstallment({
    required String installmentId,
    required String transactionId,
  }) async {
    try {
      await _client
          .from('installments')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'payment_transaction_id': transactionId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', installmentId);

      final installment = await _client
          .from('installments')
          .select('subscription_id')
          .eq('id', installmentId)
          .single();

      final paidCount = await _client
          .from('installments')
          .select()
          .eq('subscription_id', installment['subscription_id'])
          .eq('status', 'paid')
          .count();

      await _client
          .from('subscriptions')
          .update({
            'installments_paid': paidCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', installment['subscription_id']);
    } catch (e) {
      throw Exception('خطأ في دفع القسط: ${e.toString()}');
    }
  }

  Future<int> getActiveSubscriptionsCount(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .count();

      return response.count;
    } catch (e) {
      throw Exception('خطأ في تحميل عدد الاشتراكات: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getSubscriptionStats(String userId) async {
    try {
      final subscriptions = await getUserSubscriptions(userId);
      
      final activeCount = subscriptions.where((s) => s.status == SubscriptionStatus.active).length;
      final pendingCount = subscriptions.where((s) => s.status == SubscriptionStatus.pending).length;
      final totalInvested = subscriptions.fold(0.0, (sum, s) => sum + s.remainingAmount);

      return {
        'total_subscriptions': subscriptions.length,
        'active_subscriptions': activeCount,
        'pending_subscriptions': pendingCount,
        'total_invested': totalInvested,
      };
    } catch (e) {
      throw Exception('خطأ في تحميل إحصائيات الاشتراكات: ${e.toString()}');
    }
  }

  // ========== STREAM-BASED METHODS (Real-time) ==========

  /// Get user subscriptions with real-time updates
  Stream<List<SubscriptionModel>> getUserSubscriptionsStream(String userId) {
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .order('joined_at', ascending: false)
        .map((data) {
      final filtered = data.where((s) => s['user_id'] == userId).toList();
      return filtered.map((json) => SubscriptionModel.fromJson(json)).toList();
    });
  }

  /// Get single subscription by ID with real-time updates
  Stream<SubscriptionModel> getSubscriptionByIdStream(String subscriptionId) {
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .map((data) {
      final subscription = data.firstWhere(
        (s) => s['id'] == subscriptionId,
        orElse: () => throw Exception('الاشتراك غير موجود'),
      );
      return SubscriptionModel.fromJson(subscription);
    });
  }

  /// Get installments with real-time updates
  Stream<List<InstallmentModel>> getInstallmentsStream(String subscriptionId) {
    return _client
        .from('installments')
        .stream(primaryKey: ['id'])
        .order('installment_number', ascending: true)
        .map((data) {
      final filtered = data.where((i) => i['subscription_id'] == subscriptionId).toList();
      return filtered.map((json) => InstallmentModel.fromJson(json)).toList();
    });
  }

  /// Get subscription stats with real-time updates
  Stream<Map<String, dynamic>> getSubscriptionStatsStream(String userId) async* {
    await for (final subscriptions in getUserSubscriptionsStream(userId)) {
      final activeCount = subscriptions.where((s) => s.status == SubscriptionStatus.active).length;
      final pendingCount = subscriptions.where((s) => s.status == SubscriptionStatus.pending).length;
      final totalInvested = subscriptions.fold(0.0, (sum, s) => sum + s.remainingAmount);

      yield {
        'total_subscriptions': subscriptions.length,
        'active_subscriptions': activeCount,
        'pending_subscriptions': pendingCount,
        'total_invested': totalInvested,
      };
    }
  }

  /// Get active subscriptions count with real-time updates
  Stream<int> getActiveSubscriptionsCountStream(String userId) {
    return getUserSubscriptionsStream(userId).map((subscriptions) {
      return subscriptions.where((s) => s.status == SubscriptionStatus.active).length;
    });
  }

  // ========== ADMIN METHODS ==========

  /// Get all subscriptions stream (Admin only)
  Stream<List<SubscriptionModel>> getAllSubscriptionsStream() {
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .order('joined_at', ascending: false)
        .map((data) =>
            (data as List).map((json) => SubscriptionModel.fromJson(json)).toList());
  }

  /// Get pending subscriptions stream (Admin only)
  Stream<List<SubscriptionModel>> getPendingSubscriptionsStream() {
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .order('joined_at', ascending: false)
        .map((data) {
      final filtered = data.where((s) => s['status'] == 'pending').toList();
      return filtered.map((json) => SubscriptionModel.fromJson(json)).toList();
    });
  }

  /// Approve subscription (Admin only)
  Future<void> approveSubscription(String subscriptionId) async {
    try {
      await _client.from('subscriptions').update({
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);
    } catch (e) {
      throw Exception('Failed to approve subscription: $e');
    }
  }

  /// Reject subscription (Admin only)
  Future<void> rejectSubscription(String subscriptionId, String? reason) async {
    try {
      await _client.from('subscriptions').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', subscriptionId);

      // TODO: Store rejection reason if needed
    } catch (e) {
      throw Exception('Failed to reject subscription: $e');
    }
  }

  /// Get pending count for admin badge
  Future<int> getPendingSubscriptionsCount() async {
    try {
      final response = await _client
          .from('subscriptions')
          .select('id')
          .eq('status', 'pending');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}

