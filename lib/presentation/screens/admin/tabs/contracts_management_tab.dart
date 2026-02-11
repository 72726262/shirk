import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/data/models/contract_model.dart';
import 'package:intl/intl.dart';

class ContractsManagementTab extends StatefulWidget {
  const ContractsManagementTab({super.key});

  @override
  State<ContractsManagementTab> createState() => _ContractsManagementTabState();
}

class _ContractsManagementTabState extends State<ContractsManagementTab> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<ContractsManagementCubit>().loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: BlocConsumer<ContractsManagementCubit, ContractsManagementState>(
            listener: (context, state) {
              if (state is ContractsManagementError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else if (state is ContractCreatedSuccessfully) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء العقد بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ContractsManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ContractsManagementLoaded) {
                return _buildContractsTable(state.contracts);
              }

              return const Center(child: Text('لا توجد عقود'));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Dimensions.spaceM,
              children: [
                ChoiceChip(
                  label: const Text('الكل'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = null);
                      context.read<ContractsManagementCubit>().loadContracts();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('مسودة'),
                  selected: _selectedStatus == 'draft',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'draft');
                      context
                          .read<ContractsManagementCubit>()
                          .loadContracts(status: 'draft');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('قيد التوقيع'),
                  selected: _selectedStatus == 'pending_signature',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'pending_signature');
                      context
                          .read<ContractsManagementCubit>()
                          .loadContracts(status: 'pending_signature');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('موقع'),
                  selected: _selectedStatus == 'signed',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'signed');
                      context
                          .read<ContractsManagementCubit>()
                          .loadContracts(status: 'signed');
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('منفذ'),
                  selected: _selectedStatus == 'executed',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'executed');
                      context
                          .read<ContractsManagementCubit>()
                          .loadContracts(status: 'executed');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.spaceL),
          ElevatedButton.icon(
            onPressed: _showCreateContractDialog,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء عقد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTable(List<ContractModel> contracts) {
    if (contracts.isEmpty) {
      return const Center(
        child: Text('لا توجد عقود'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('رقم العقد')),
          DataColumn(label: Text('العنوان')),
          DataColumn(label: Text('المستخدم')),
          DataColumn(label: Text('المشروع')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('تاريخ الإنشاء')),
          DataColumn(label: Text('الإجراءات')),
        ],
        rows: contracts.map((contract) {
          return DataRow(cells: [
            DataCell(Text(contract.contractNumber)),
            DataCell(Text(contract.title)),
            DataCell(Text(contract.userId)), // يمكن تحسينها لعرض اسم المستخدم
            DataCell(Text(contract.projectId ?? '-')),
            DataCell(_buildStatusChip(contract.status)),
            DataCell(Text(DateFormat('dd/MM/yyyy').format(contract.createdAt))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'عرض',
                    onPressed: () => _viewContract(contract),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'تعديل',
                    onPressed: () => _editContract(contract),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                    tooltip: 'حذف',
                    onPressed: () => _deleteContract(contract.id),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(ContractStatus status) {
    Color color;
    String label;

    switch (status) {
      case ContractStatus.draft:
        color = AppColors.textSecondary;
        label = 'مسودة';
        break;
      case ContractStatus.pendingSignature:
        color = AppColors.warning;
        label = 'قيد التوقيع';
        break;
      case ContractStatus.signed:
        color = AppColors.success;
        label = 'موقع';
        break;
      case ContractStatus.executed:
        color = AppColors.primary;
        label = 'منفذ';
        break;
      case ContractStatus.terminated:
        color = AppColors.error;
        label = 'ملغي';
        break;
      case ContractStatus.expired:
        color = Colors.grey;
        label = 'منتهي';
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
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  void _showCreateContractDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء عقد جديد'),
        content: const Text('هذه الميزة ستكون متاحة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _viewContract(ContractModel contract) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contract.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رقم العقد: ${contract.contractNumber}'),
              const SizedBox(height: Dimensions.spaceS),
              Text('الحالة: ${_getStatusLabel(contract.status)}'),
              const SizedBox(height: Dimensions.spaceS),
              Text(
                'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy').format(contract.createdAt)}',
              ),
              if (contract.clientSignedAt != null) ...[
                const SizedBox(height: Dimensions.spaceS),
                Text(
                  'تاريخ التوقيع: ${DateFormat('dd/MM/yyyy').format(contract.clientSignedAt!)}',
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _editContract(ContractModel contract) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ميزة التعديل قيد التطوير')),
    );
  }

  void _deleteContract(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العقد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<ContractsManagementCubit>().deleteContract(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(ContractStatus status) {
    switch (status) {
      case ContractStatus.draft:
        return 'مسودة';
      case ContractStatus.pendingSignature:
        return 'قيد التوقيع';
      case ContractStatus.signed:
        return 'موقع';
      case ContractStatus.executed:
        return 'منفذ';
      case ContractStatus.terminated:
        return 'ملغي';
      case ContractStatus.expired:
        return 'منتهي';
    }
  }
}
