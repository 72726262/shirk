import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionsTab extends StatefulWidget {
  final String userId;

  const TransactionsTab({super.key, required this.userId});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  // TODO: Create TransactionService to fetch user transactions
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;
  TransactionType? _selectedType;

  @override
  void initState() {
    super.initState();
    // _loadTransactions(); // TODO: Uncomment when TransactionService is ready
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Create TransactionService and implement getUserTransactions
      // final transactions = await _transactionService.getUserTransactions(
      //   userId: widget.userId,
      //   type: _selectedType,
      // );
      setState(() {
        // _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعاملات المالية'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('الكل', null),
                  const SizedBox(width: Dimensions.spaceS),
                  ...TransactionType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(left: Dimensions.spaceS),
                      child: _buildFilterChip(_getTypeLabel(type), type),
                    ),
                  ),
                ],
              ),
            ),
          ),
          //Transactions List
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
        _loadTransactions();
      },
      backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Dimensions.spaceM),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: Dimensions.spaceM),
            Text(
              _selectedType != null
                  ? 'لا توجد معاملات من نوع ${_getTypeLabel(_selectedType!)}'
                  : 'لا توجد معاملات',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: Dimensions.screenPadding,
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isCredit =
        transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.refund;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(Dimensions.spaceM),
        leading: CircleAvatar(
          backgroundColor: _getTransactionColor(
            transaction.type,
          ).withOpacity(0.1),
          child: Icon(
            _getTransactionIcon(transaction.type),
            color: _getTransactionColor(transaction.type),
          ),
        ),
        title: Text(
          _getTypeLabel(transaction.type),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.spaceXS),
            if (transaction.description != null) Text(transaction.description!),
            const SizedBox(height: Dimensions.spaceXS),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: Dimensions.spaceXS),
            _buildStatusChip(transaction.status),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : '-'} ${transaction.amount.toStringAsFixed(0)} ر.س',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isCredit ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String label;

    switch (status) {
      case TransactionStatus.pending:
        color = AppColors.warning;
        label = 'قيد الانتظار';
        break;
      case TransactionStatus.processing:
        color = AppColors.info;
        label = 'قيد المعالجة';
        break;
      case TransactionStatus.completed:
        color = AppColors.success;
        label = 'مكتمل';
        break;
      case TransactionStatus.failed:
        color = AppColors.error;
        label = 'فشل';
        break;
      case TransactionStatus.cancelled:
        color = AppColors.textSecondary;
        label = 'ملغي';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'إيداع';
      case TransactionType.withdrawal:
        return 'سحب';
      case TransactionType.payment:
        return 'دفع';
      case TransactionType.refund:
        return 'استرداد';
      case TransactionType.commission:
        return 'عمولة';
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
      case TransactionType.refund:
        return AppColors.success;
      case TransactionType.withdrawal:
      case TransactionType.payment:
        return AppColors.error;
      case TransactionType.commission:
        return AppColors.warning;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return Icons.arrow_downward;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.commission:
        return Icons.account_balance;
    }
  }
}
