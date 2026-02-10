import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/wallet_model.dart';

class WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback onAddFunds;
  final VoidCallback onWithdraw;

  const WalletCard({
    super.key,
    required this.wallet,
    required this.onAddFunds,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final availableBalance = wallet.balance - wallet.reservedBalance;

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceXL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white,
                size: 32,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: const Text(
                  'المحفظة',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceXL),
          Text(
            'الرصيد الحالي',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: Dimensions.spaceS),
          Text(
            '${wallet.balance.toStringAsFixed(2)} ج.م',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: Dimensions.spaceXL),
          Row(
            children: [
              _buildBalanceItem(
                context,
                title: 'المتاح',
                amount: availableBalance,
                color: AppColors.accent,
              ),
              const SizedBox(width: Dimensions.spaceXL),
              _buildBalanceItem(
                context,
                title: 'محجوز',
                amount: wallet.reservedBalance,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceL),
          const Divider(color: Colors.white24),
          const SizedBox(height: Dimensions.spaceM),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.add,
                  label: 'إضافة رصيد',
                  onTap: onAddFunds,
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.arrow_downward,
                  label: 'سحب',
                  onTap: onWithdraw,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context, {
    required String title,
    required double amount,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          '${amount.toStringAsFixed(2)} ج.م',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(Dimensions.radiusM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
