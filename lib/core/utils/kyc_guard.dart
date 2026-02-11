import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/routes/route_names.dart';

class KycGuard {
  /// Checks if user has approved KYC status
  static bool isKycApproved(UserModel user) {
    return user.kycStatus == KYCStatus.approved;
  }

  /// Shows KYC required dialog and returns false if KYC not approved
  static Future<bool> requireKycApproval(
    BuildContext context,
    UserModel user, {
    String? customMessage,
  }) async {
    if (isKycApproved(user)) {
      return true;
    }

    // Show KYC required dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text('التحقق من الهوية مطلوب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customMessage ??
                  'للاستمرار في هذا الإجراء، يجب أن يكون حسابك موثّقاً.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildStatusInfo(user.kycStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          if (user.kycStatus == KYCStatus.pending)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteNames.kycVerification);
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('ابدأ التحقق'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );

    return false;
  }

  static Widget _buildStatusInfo(KYCStatus status) {
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case KYCStatus.pending:
        message = 'الحالة: لم تبدأ عملية التحقق بعد';
        color = AppColors.textSecondary;
        icon = Icons.pending_outlined;
        break;
      case KYCStatus.underReview:
        message = 'الحالة: طلبك قيد المراجعة حالياً';
        color = AppColors.info;
        icon = Icons.schedule;
        break;
      case KYCStatus.rejected:
        message = 'الحالة: تم رفض طلبك، يرجى المحاولة مرة أخرى';
        color = AppColors.error;
        icon = Icons.error_outline;
        break;
      case KYCStatus.approved:
        message = 'الحالة: موثّق ✓';
        color = AppColors.success;
        icon = Icons.verified_user;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
