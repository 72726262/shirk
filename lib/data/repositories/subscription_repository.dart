import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/services/supabase_service.dart';

class SubscriptionRepository {
  final SupabaseService _supabaseService;
  
  SubscriptionRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  SupabaseClient get _client => _supabaseService.client;

  // Get user subscriptions
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

  // Alias for backward compatibility
  Future<List<SubscriptionModel>> getSubscriptionsByUser(String userId) =>
      getUserSubscriptions(userId);

  // Get subscription by ID
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

  // Create subscription (Join project)
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

  // Update subscription status
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

  // Sign contract
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

  // Upload signature
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

  // Get subscription installments
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

  // Pay installment
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

      // Update subscription installments_paid count
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

  // Get active subscriptions count
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

  // Get subscription statistics
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
}
