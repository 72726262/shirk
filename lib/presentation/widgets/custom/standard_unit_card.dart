import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/screens/units/unit_detail_booking_screen.dart';

class StandardUnitCard extends StatelessWidget {
  final UnitModel unit;
  final ProjectModel project;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StandardUnitCard({
    super.key,
    required this.unit,
    required this.project,
    this.onEdit,
    this.onDelete,
  });

  Color _getStatusColor(UnitStatus status) {
    switch (status) {
      case UnitStatus.available:
        return AppColors.success;
      case UnitStatus.reserved:
        return AppColors.warning;
      case UnitStatus.sold:
        return AppColors.error;
      case UnitStatus.blocked:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(unit.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusM),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${unit.unitNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          unit.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Icon
                  Center(
                    child: Icon(
                      unit.unitType == UnitType.villa
                          ? Icons.villa
                          : Icons.apartment,
                      size: 40,
                      color: AppColors.gray300,
                    ),
                  ),
                  const Spacer(),
                  const Divider(height: 8),
                  const SizedBox(height: 4),
                  // Details
                  Row(
                    children: [
                      const Icon(
                        Icons.straighten,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${unit.areaSqm} م²',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${unit.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final isAdmin =
                  state is Authenticated &&
                  (state.user.role == 'admin' ||
                      state.user.role == 'super_admin');

              if (isAdmin) {
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.gray200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('تعديل'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(width: 1, height: 24, color: AppColors.gray200),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('حذف'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (unit.status == UnitStatus.available) {
                // Client View: Book Button -> Unit Details
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (state is Authenticated &&
                          state.user.kycStatus != KYCStatus.approved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'لم يتم توثيق حسابك يرجي رفع المستندات اولا',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UnitDetailBookingScreen(
                            project: project,
                            unit: unit,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('التفاصيل والحجز'),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
