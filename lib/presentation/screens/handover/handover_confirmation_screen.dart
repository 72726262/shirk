import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/routes/route_names.dart';

class HandoverConfirmationScreen extends StatelessWidget {
  final String unitId;

  const HandoverConfirmationScreen({super.key, required this.unitId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceXXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.key,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: Dimensions.spaceXXL),

              Text(
                'مبروك!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),

              Text(
                'تم تسليم الوحدة بنجاح',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spaceL),

              Text(
                'تهانينا على استلام وحدتك. يمكنك الآن الوصول إلى جميع مستندات الوحدة والمعلومات من التطبيق',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.spaceXXL),

              // Info Cards
              _buildInfoCard(
                icon: Icons.description,
                title: 'المستندات',
                subtitle: 'جميع مستندات الوحدة متاحة',
                color: AppColors.primary,
              ),
              const SizedBox(height: Dimensions.spaceL),

              _buildInfoCard(
                icon: Icons.support_agent,
                title: 'الدعم',
                subtitle: 'نحن هنا لمساعدتك في أي وقت',
                color: AppColors.info,
              ),
              const Spacer(),

              PrimaryButton(
                text: 'العودة إلى لوحة التحكم',
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteNames.dashboard,
                    (route) => false,
                  );
                },
                leadingIcon: Icons.home,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: Dimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
