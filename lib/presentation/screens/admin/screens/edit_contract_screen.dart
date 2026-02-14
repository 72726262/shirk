import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/contract_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';

import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';

class EditContractScreen extends StatefulWidget {
  final ContractModel contract;

  const EditContractScreen({super.key, required this.contract});

  @override
  State<EditContractScreen> createState() => _EditContractScreenState();
}

class _EditContractScreenState extends State<EditContractScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedProjectId;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _contractNumberController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _titleController = TextEditingController(text: widget.contract.title);
    _contentController = TextEditingController(text: widget.contract.content);
    _contractNumberController = TextEditingController(
      text: widget.contract.contractNumber,
    );

    // Check for amount in terms if available
    String amountText = '';
    if (widget.contract.terms != null &&
        widget.contract.terms!.containsKey('amount')) {
      amountText = widget.contract.terms!['amount'].toString();
    }
    _amountController = TextEditingController(text: amountText);

    _selectedClientId = widget.contract.userId;
    _selectedProjectId = widget.contract.projectId;

    // Load dropdown data
    context.read<ClientManagementCubit>().loadClients();
    context.read<ProjectsCubit>().loadProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contractNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار العميل'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final amount = double.tryParse(_amountController.text);

      context.read<ContractsManagementCubit>().updateContract(
        contractId: widget.contract.id,
        title: _titleController.text,
        content: _contentController.text,
        amount: amount,
        terms: amount != null ? {'amount': amount} : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل العقد'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<ContractsManagementCubit, ContractsManagementState>(
        listener: (context, state) {
          if (state is ContractsManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ContractUpdatedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تحديث العقد بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context); // Close screen
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Contract Info Header
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'رقم العقد: ${widget.contract.contractNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الحالة: ${widget.contract.status.name}',
                        style: TextStyle(
                          color: widget.contract.status.name == 'signed'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Client Selector (Read Only or Editable? Let's keep it editable but warn) ===
                const Text(
                  'العميل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: Dimensions.spaceS),
                BlocBuilder<ClientManagementCubit, ClientManagementState>(
                  builder: (context, state) {
                    if (state is ClientManagementLoading) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    List<UserModel> clients = [];
                    if (state is ClientManagementLoaded) {
                      clients = state.clients;
                    }

                    // Ensure selected ID is in list or add it temporarily if missing (lazy loading handling)
                    // For now, simpler approach:
                    return DropdownButtonFormField<String>(
                      value: _selectedClientId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر العميل',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: clients.map((client) {
                        return DropdownMenuItem(
                          value: client.id,
                          child: Text(
                            '${client.fullName ?? 'غير محدد'} (${client.email})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged:
                          null, // Disable changing client for now to avoid complexity
                      disabledHint: Text(
                        clients
                            .firstWhere(
                              (c) => c.id == _selectedClientId,
                              orElse: () => UserModel(
                                id: '',
                                email: 'جاري التحميل...',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            )
                            .email,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '* لا يمكن تغيير العميل بعد إنشاء العقد',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Project Selector ===
                const Text(
                  'المشروع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: Dimensions.spaceS),
                BlocBuilder<ProjectsCubit, ProjectsState>(
                  builder: (context, state) {
                    if (state is ProjectsLoading) {
                      return const Center(child: LinearProgressIndicator());
                    }

                    List<ProjectModel> projects = [];
                    if (state is ProjectsLoaded) {
                      projects = state.projects;
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اختر المشروع (اختياري)',
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        );
                      }).toList(),
                      onChanged: null, // Disable changing project too
                      disabledHint: Text(
                        projects
                            .firstWhere(
                              (p) => p.id == _selectedProjectId,
                              orElse: () => ProjectModel(
                                id: '',
                                name: 'غير محدد',
                                nameAr: '',
                                status: ProjectStatus.planning,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                            )
                            .name,
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Contract Details ===
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان العقد',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: Dimensions.spaceL),

                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'القيمة (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                TextFormField(
                  controller: _contentController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'نص العقد',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Submit Button ===
                BlocBuilder<ContractsManagementCubit, ContractsManagementState>(
                  builder: (context, state) {
                    if (state is ContractsManagementLoading) {
                      // Using Loading state since we emit Loading in updateContract
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
