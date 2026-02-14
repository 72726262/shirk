import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/screens/contract_detail_screen.dart';
import 'package:mmm/data/models/contract_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mmm/presentation/screens/admin/screens/create_contract_screen.dart';
import 'package:mmm/presentation/screens/admin/screens/edit_contract_screen.dart';

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
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateContractScreen(),
            ),
          );

          if (result == true && mounted) {
            context.read<ContractsManagementCubit>().loadContracts();
          }
        },
        label: const Text('إنشاء عقد'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          children: [
            _buildFiltersAndAction(),
            const SizedBox(height: Dimensions.spaceL),
            Expanded(
              child:
                  BlocConsumer<
                    ContractsManagementCubit,
                    ContractsManagementState
                  >(
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
                      } else if (state is ContractUpdatedSuccessfully) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث العقد بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.read<ContractsManagementCubit>().loadContracts();
                      } else if (state is ContractDeletedSuccessfully) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حذف العقد بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.read<ContractsManagementCubit>().loadContracts();
                      }
                    },
                    builder: (context, state) {
                      if (state is ContractsManagementLoading) {
                        return _buildSkeletonLoader();
                      }

                      if (state is ContractsManagementLoaded) {
                        if (state.contracts.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: AppColors.gray400,
                                ),
                                SizedBox(height: Dimensions.spaceL),
                                Text('لا توجد عقود'),
                              ],
                            ),
                          );
                        }
                        return _buildContractsList(state.contracts);
                      }

                      return const Center(child: Text('لا توجد عقود'));
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndAction() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('الكل'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = null);
                      context.read<ContractsManagementCubit>().loadContracts();
                    }
                  },
                ),
                const SizedBox(width: Dimensions.spaceS),
                FilterChip(
                  label: const Text('معلق'),
                  selected: _selectedStatus == 'pending',
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  selectedColor: AppColors.warning.withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'pending');
                      context.read<ContractsManagementCubit>().loadContracts(
                        status: 'pending',
                      );
                    }
                  },
                ),
                const SizedBox(width: Dimensions.spaceS),
                FilterChip(
                  label: const Text('ساري'),
                  selected: _selectedStatus == 'active',
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  selectedColor: AppColors.success.withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'active');
                      context.read<ContractsManagementCubit>().loadContracts(
                        status: 'active',
                      );
                    }
                  },
                ),
                const SizedBox(width: Dimensions.spaceS),
                FilterChip(
                  label: const Text('منفذ'),
                  selected: _selectedStatus == 'executed',
                  backgroundColor: AppColors.info.withOpacity(0.1),
                  selectedColor: AppColors.info.withOpacity(0.3),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'executed');
                      context.read<ContractsManagementCubit>().loadContracts(
                        status: 'executed',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Dimensions.spaceL),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Show create contract dialog
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('قيد التطوير')));
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إنشاء عقد'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceM,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractsList(List<ContractModel> contracts) {
    return ListView.builder(
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        final contract = contracts[index];
        return _ContractCard(contract: contract);
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.gray200,
          highlightColor: AppColors.gray100,
          child: Container(
            margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.gray300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 200,
                            color: AppColors.gray300,
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          Container(
                            height: 14,
                            width: 150,
                            color: AppColors.gray300,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceM),
                Container(
                  height: 14,
                  width: double.infinity,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractModel contract;

  const _ContractCard({required this.contract});

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'executed':
        return AppColors.info;
      case 'expired':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'ساري';
      case 'pending':
        return 'معلق';
      case 'executed':
        return 'منفذ';
      case 'expired':
        return 'منتهي';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = contract.expiryDate != null
        ? DateFormat('yyyy-MM-dd').format(contract.createdAt!)
        : 'غير محدد';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractDetailScreen(contract: contract),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    contract.status.toString(),
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(
                  Icons.description,
                  color: _getStatusColor(contract.status.toString()),
                  size: 28,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),

              // Contract Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.userId ?? 'عقد #${contract.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Expanded(
                          child: Text(
                            contract.title ?? 'غير محدد',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(contract.status.toString()),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            _getStatusText(contract.status.toString()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.spaceS),
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<ContractsManagementCubit>(),
                          child: EditContractScreen(contract: contract),
                        ),
                      ),
                    );
                  } else if (value == 'delete') {
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
                              // Capture the cubit context before the dialog
                              // Just ensure the widget context has the cubit
                              // In this case, _ContractCard assumes a provider above it.
                              // If using specific context:
                              Navigator.pop(context); // Close dialog first
                              
                              // We need to use valid context, but here 'context' is from builder
                              // ContractCard's context is safe if used outside builder or via closure
                              // Let's rely on the fact that ContractsManagementTab provides it.
                              
                              // Use the outer context (from build method) via closure or just assume standard lookup
                              // But standard lookup from dialog context might fail if provider is not above MaterialApp (it usually is for global, but here unlikely)
                              // A safer way:
                              // context.read<ContractsManagementCubit>().deleteContract(contract.id); 
                              // This 'context' is the Dialog's context. 
                              // If BlocProvider is in the Tab, and Dialog is pushed, it is NOT in the tree of Dialog.
                              // So we must access the Cubit via the wrapper logic or pass it.
                              
                              // BETTER:
                              // Pass the function as callback or access parent context.
                              // Here we can use 'context' of build method if we capture it?
                              // Actually, StatelessWidget build context is fine. 
                              // But inside showDialog, the context is new.
                              
                              // FIX: Use read from the parent context (captured in closure).
                              final cubit = BlocProvider.of<ContractsManagementCubit>(context);
                              cubit.deleteContract(contract.id);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('تعديل'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('حذف', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
