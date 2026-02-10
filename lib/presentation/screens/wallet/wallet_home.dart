import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/wallet_model.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/presentation/widgets/custom/wallet_card.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  int _selectedFilter = 0; // 0: All, 1: Deposit, 2: Withdrawal, 3: Payments

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // View full transaction history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wallet Card
            // Wallet Card
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: WalletCard(
                wallet: WalletModel(
                  id: '1',
                  userId: 'current_user',
                  balance: 150000,
                  reservedBalance: 45000,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
                onAddFunds: () => Navigator.pushNamed(context, RouteNames.addFunds),
                onWithdraw: () => Navigator.pushNamed(context, RouteNames.withdrawFunds),
              ),
            ),

            // Quick Actions
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
                vertical: Dimensions.spaceM,
              ),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'إيداع',
                      color: AppColors.success,
                      onTap: () {
                        Navigator.pushNamed(context, '/add-funds');
                      },
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.remove_circle_outline,
                      label: 'سحب',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pushNamed(context, '/withdraw-funds');
                      },
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.swap_horiz,
                      label: 'تحويل',
                      color: AppColors.accent,
                      onTap: () {
                        // Navigate to transfer
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Transaction History Header
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'سجل المعاملات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<int>(
                    onSelected: (value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0,
                        child: Text('جميع المعاملات'),
                      ),
                      const PopupMenuItem(value: 1, child: Text('الإيداعات')),
                      const PopupMenuItem(value: 2, child: Text('السحوبات')),
                      const PopupMenuItem(value: 3, child: Text('المدفوعات')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Text('تصفية'),
                          const SizedBox(width: Dimensions.spaceXS),
                          const Icon(Icons.filter_list, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transaction List
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
              ),
              child: Column(
                children: [
                  _buildTransactionItem(
                    type: 'إيداع',
                    amount: '+50,000 ج.م',
                    date: 'اليـوم - 14:30',
                    status: 'مكتمل',
                    statusColor: AppColors.success,
                    description: 'تحويل بنكي',
                    icon: Icons.account_balance,
                    iconColor: AppColors.success,
                  ),
                  _buildTransactionItem(
                    type: 'دفع',
                    amount: '-22,500 ج.م',
                    date: 'أمس - 10:15',
                    status: 'مكتمل',
                    statusColor: AppColors.success,
                    description: 'قسط مشروع النخيل',
                    icon: Icons.apartment,
                    iconColor: AppColors.primary,
                  ),
                  _buildTransactionItem(
                    type: 'سحب',
                    amount: '-10,000 ج.م',
                    date: '٢٠ فبراير - 16:45',
                    status: 'قيد المراجعة',
                    statusColor: AppColors.warning,
                    description: 'إلى حسابي البنكي',
                    icon: Icons.account_balance_wallet,
                    iconColor: AppColors.primary,
                  ),
                  _buildTransactionItem(
                    type: 'إيداع',
                    amount: '+100,000 ج.م',
                    date: '١٥ فبراير - 11:20',
                    status: 'مكتمل',
                    statusColor: AppColors.success,
                    description: 'بطاقة ائتمان',
                    icon: Icons.credit_card,
                    iconColor: AppColors.success,
                  ),
                  _buildTransactionItem(
                    type: 'دفع',
                    amount: '-15,000 ج.م',
                    date: '١٠ فبراير - 09:30',
                    status: 'مكتمل',
                    statusColor: AppColors.success,
                    description: 'دفعة أولى - فيلات الريف',
                    icon: Icons.villa,
                    iconColor: AppColors.accent,
                  ),
                  _buildTransactionItem(
                    type: 'ربح',
                    amount: '+5,200 ج.م',
                    date: '٥ فبراير - 14:00',
                    status: 'مكتمل',
                    statusColor: AppColors.success,
                    description: 'أرباح استثمارية',
                    icon: Icons.trending_up,
                    iconColor: AppColors.success,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spaceXL),

            // View All Button
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to full transaction history
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('عرض جميع المعاملات'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),

      // Add Funds FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-funds');
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة رصيد'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: Dimensions.spaceS),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String type,
    required String amount,
    required String date,
    required String status,
    required Color statusColor,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    final isPositive = amount.startsWith('+');

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),

          const SizedBox(width: Dimensions.spaceL),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      amount,
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: Dimensions.spaceXS),

                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: Dimensions.spaceXS),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      date,
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
