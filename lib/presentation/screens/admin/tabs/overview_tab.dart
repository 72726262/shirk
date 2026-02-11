import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminDashboardLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<AdminDashboardCubit>().refreshDashboard();
            },
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(Dimensions.spaceXXL),
              mainAxisSpacing: Dimensions.spaceL,
              crossAxisSpacing: Dimensions.spaceL,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'إجمالي العملاء',
                  state.stats.totalClients.toString(),
                  Icons.people,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'المشاريع النشطة',
                  state.stats.activeProjects.toString(),
                  Icons.business,
                  AppColors.success,
                ),
                _buildStatCard(
                  'إجمالي الإيرادات',
                  '${state.stats.totalRevenue} ر.س',
                  Icons.attach_money,
                  AppColors.warning,
                ),
                _buildStatCard(
                  'المدفوعات المعلقة',
                  state.stats.pendingPayments.toString(),
                  Icons.pending,
                  AppColors.error,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: Dimensions.spaceXS),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
