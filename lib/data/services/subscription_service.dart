import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/data/services/wallet_service.dart';
import 'package:mmm/data/services/project_service.dart';

/// Subscription Service - Handles subscription/join project business logic
class SubscriptionService {
  final SubscriptionRepository _subscriptionRepository;
  final WalletService _walletService;
  final ProjectService _projectService;

  SubscriptionService({
    SubscriptionRepository? subscriptionRepository,
    WalletService? walletService,
    ProjectService? projectService,
  })  : _subscriptionRepository =
            subscriptionRepository ?? SubscriptionRepository(),
        _walletService = walletService ?? WalletService(),
        _projectService = projectService ?? ProjectService();

  // Get user subscriptions with project details
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId) async {
    try {
      return await _subscriptionRepository.getUserSubscriptions(userId);
    } catch (e) {
      throw Exception('فشل تحميل الاشتراكات: ${e.toString()}');
    }
  }

  // Join project (create subscription) with validation
  Future<SubscriptionModel> joinProject({
    required String userId,
    required String projectId,
    String? unitId,
    required double investmentAmount,
    double? ownershipPercentage,
    double? downPayment,
    int installmentsCount = 0,
  }) async {
    try {
      // Validate investment amount
      if (investmentAmount <= 0) {
        throw Exception('مبلغ الاستثمار يجب أن يكون أكبر من صفر');
      }

      // Check wallet balance for down payment
      if (downPayment != null && downPayment > 0) {
        final walletDashboard = await _walletService.getWalletDashboard(userId);
        final availableBalance = walletDashboard['available_balance'] as double;

        if (downPayment > availableBalance) {
          throw Exception('الرصيد المتاح غير كافٍ للدفعة الأولى');
        }
      }

      // Verify unit is available if specified
      if (unitId != null) {
        final projectDetails = await _projectService.getProjectDetails(projectId);
        final availableUnits = projectDetails['availableUnits'] as List;
        
        final unitAvailable = availableUnits.any((u) => u.id == unitId);
        if (!unitAvailable) {
          throw Exception('الوحدة المحددة غير متاحة');
        }
      }

      // Create subscription
      return await _subscriptionRepository.createSubscription(
        userId: userId,
        projectId: projectId,
        unitId: unitId,
        investmentAmount: investmentAmount,
        ownershipPercentage: ownershipPercentage,
        downPayment: downPayment,
        installmentsCount: installmentsCount,
      );
    } catch (e) {
      throw Exception('فشل الانضمام للمشروع: ${e.toString()}');
    }
  }

  // Sign contract with signature upload
  Future<SubscriptionModel> signContract({
    required String subscriptionId,
    required String signaturePath,
  }) async {
    try {
      final signatureUrl = await _subscriptionRepository.uploadSignature(
        subscriptionId: subscriptionId,
        signatureData: signaturePath,
      );

      await _subscriptionRepository.signContract(
        subscriptionId: subscriptionId,
        signatureUrl: signatureUrl,
      );

      return await _subscriptionRepository.getSubscriptionById(subscriptionId);
    } catch (e) {
      throw Exception('فشل توقيع العقد: ${e.toString()}');
    }
  }

  // Create subscription directly (used by JoinFlowCubit)
  Future<SubscriptionModel> createSubscription({
    required String userId,
    required String projectId,
    String? unitId,
    required double investmentAmount,
    double? ownershipPercentage,
    double? downPayment,
    int installmentsCount = 0,
  }) async {
    return joinProject(
      userId: userId,
      projectId: projectId,
      unitId: unitId,
      investmentAmount: investmentAmount,
      ownershipPercentage: ownershipPercentage,
      downPayment: downPayment,
      installmentsCount: installmentsCount,
    );
  }

  // Get subscription by ID
  Future<SubscriptionModel> getSubscriptionById(String subscriptionId) async {
    try {
      return await _subscriptionRepository.getSubscriptionById(subscriptionId);
    } catch (e) {
      throw Exception('فشل تحميل الاشتراك: ${e.toString()}');
    }
  }

  // Get installments for subscription
  Future<List<InstallmentModel>> getInstallments(String subscriptionId) async {
    try {
      return await _subscriptionRepository.getInstallments(subscriptionId);
    } catch (e) {
      throw Exception('فشل تحميل الأقساط: ${e.toString()}');
    }
  }

  // Pay installment with wallet balance check
  Future<void> payInstallment({
    required String installmentId,
    required String userId,
  }) async {
    try {
      // Get installment details
      final installments = await _subscriptionRepository.getInstallments('');
      final installment = installments.firstWhere((i) => i.id == installmentId);

      // Check wallet balance
      final walletDashboard = await _walletService.getWalletDashboard(userId);
      final availableBalance = walletDashboard['available_balance'] as double;

      if (installment.amount > availableBalance) {
        throw Exception('الرصيد المتاح غير كافٍ لدفع القسط');
      }

      // Create transaction record for wallet payment
      // In a real app, this should be done via a dedicated TransactionService or WalletService method
      // that returns the transaction ID. For now, we simulate it or pass a placeholder/UUID.
      final transactionId = 'wallet_pay_${DateTime.now().millisecondsSinceEpoch}';

      // Process payment
      await _subscriptionRepository.payInstallment(
        installmentId: installmentId,
        transactionId: transactionId,
      );
    } catch (e) {
      throw Exception('فشل دفع القسط: ${e.toString()}');
    }
  }

  // Get subscription statistics
  Future<Map<String, dynamic>> getSubscriptionStats(String userId) async {
    try {
      return await _subscriptionRepository.getSubscriptionStats(userId);
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات الاشتراكات: ${e.toString()}');
    }
  }

  // Get subscription details with all related data
  Future<Map<String, dynamic>> getSubscriptionDetails(
    String subscriptionId,
  ) async {
    try {
      final subscriptions = await _subscriptionRepository.getUserSubscriptions('');
      final subscription = subscriptions.firstWhere((s) => s.id == subscriptionId);
      final installments = await _subscriptionRepository.getInstallments(subscriptionId);

      return {
        'subscription': subscription,
        'installments': installments,
        'paid_installments': installments.where((i) => i.isPaid).length,
        'pending_installments': installments.where((i) => i.isPending).length,
        'overdue_installments': installments.where((i) => i.isOverdue).length,
        'next_due_installment': installments
            .where((i) => i.isPending)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
      };
    } catch (e) {
      throw Exception('فشل تحميل تفاصيل الاشتراك: ${e.toString()}');
    }
  }
}
