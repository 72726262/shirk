import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/admin_repository.dart';

/// Admin Service - Handles admin panel business logic
class AdminService {
  final AdminRepository _adminRepository;

  AdminService({AdminRepository? adminRepository})
      : _adminRepository = adminRepository ?? AdminRepository();

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _adminRepository.getDashboardStats();
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات اللوحة: ${e.toString()}');
    }
  }

  // Get all clients with filters
  Future<List<UserModel>> getClients({
    String? kycStatus,
    String? role,
    String? searchQuery,
  }) async {
    try {
      return await _adminRepository.getClients(
        kycStatus: kycStatus,
        role: role,
        searchQuery: searchQuery,
      );
    } catch (e) {
      throw Exception('فشل تحميل العملاء: ${e.toString()}');
    }
  }

  // Get clients pending KYC approval
  Future<List<UserModel>> getPendingKYC() async {
    try {
      return await _adminRepository.getClients(kycStatus: 'pending');
    } catch (e) {
      throw Exception('فشل تحميل طلبات التحقق: ${e.toString()}');
    }
  }

  // Approve KYC with notification
  Future<UserModel> approveKYC(String userId) async {
    try {
      return await _adminRepository.approveKYC(userId);
    } catch (e) {
      throw Exception('فشل الموافقة على التحقق: ${e.toString()}');
    }
  }

  // Reject KYC with reason and notification
  Future<UserModel> rejectKYC({
    required String userId,
    required String reason,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        throw Exception('يجب إدخال سبب الرفض');
      }

      return await _adminRepository.rejectKYC(
        userId: userId,
        reason: reason,
      );
    } catch (e) {
      throw Exception('فشل رفض التحقق: ${e.toString()}');
    }
  }

  // Get all payments/transactions with filters
  Future<List<dynamic>> getPayments({
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _adminRepository.getPayments(
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      throw Exception('فشل تحميل المدفوعات: ${e.toString()}');
    }
  }

  // Get activity logs with filters
  Future<List<dynamic>> getActivityLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      return await _adminRepository.getActivityLogs(
        userId: userId,
        action: action,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('فشل تحميل سجل الأنشطة: ${e.toString()}');
    }
  }

  // Log admin activity
  Future<void> logActivity({
    required String action,
    String? entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _adminRepository.logActivity(
        action: action,
        entityType: entityType,
        entityId: entityId,
        description: description,
        metadata: metadata,
      );
    } catch (e) {
      // Silent fail for logging
      print('Failed to log activity: ${e.toString()}');
    }
  }

  // Get monthly revenue data for charts
  Future<List<Map<String, dynamic>>> getMonthlyRevenue({
    int months = 12,
  }) async {
    try {
      return await _adminRepository.getMonthlyRevenue(months: months);
    } catch (e) {
      throw Exception('فشل تحميل بيانات الإيرادات: ${e.toString()}');
    }
  }

  // Get platform statistics
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      return await _adminRepository.getPlatformStats();
    } catch (e) {
      throw Exception('فشل تحميل إحصائيات المنصة: ${e.toString()}');
    }
  }

  // Get comprehensive admin overview
  Future<Map<String, dynamic>> getAdminOverview() async {
    try {
      final dashboardStats = await _adminRepository.getDashboardStats();
      final platformStats = await _adminRepository.getPlatformStats();
      final pendingKYC = await getPendingKYC();
      final monthlyRevenue = await _adminRepository.getMonthlyRevenue(months: 6);

      return {
        'dashboard': dashboardStats,
        'platform': platformStats,
        'pending_kyc_count': pendingKYC.length,
        'revenue_trend': monthlyRevenue,
      };
    } catch (e) {
      throw Exception('فشل تحميل نظرة عامة للمدير: ${e.toString()}');
    }
  }

  // Bulk approve KYC
  Future<List<UserModel>> bulkApproveKYC(List<String> userIds) async {
    try {
      final results = <UserModel>[];
      for (final userId in userIds) {
        try {
          final user = await _adminRepository.approveKYC(userId);
          results.add(user);
        } catch (e) {
          // Continue with next user even if one fails
          print('Failed to approve KYC for user $userId: ${e.toString()}');
        }
      }
      return results;
    } catch (e) {
      throw Exception('فشل الموافقة الجماعية: ${e.toString()}');
    }
  }
}
