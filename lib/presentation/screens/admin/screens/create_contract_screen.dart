import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';

import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/presentation/widgets/dialogs/searchable_project_picker.dart';
import 'package:mmm/presentation/widgets/dialogs/searchable_client_picker.dart';
import 'package:intl/intl.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedProjectId;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load data
    context.read<ClientManagementCubit>().loadClients();
    context.read<ProjectsCubit>().loadProjects();

    // Auto-generate contract number
    _generateContractNumber();
  }

  void _generateContractNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    final dateToken = DateFormat('yyMM').format(DateTime.now());
    _contractNumberController.text = 'CN-$dateToken-$timestamp';
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

      context.read<ContractsManagementCubit>().createManualContract(
        userId: _selectedClientId!,
        projectId: _selectedProjectId,
        title: _titleController.text,
        content: _contentController.text,
        contractNumber: _contractNumberController.text,
        amount: amount,
        terms: amount != null ? {'amount': amount} : null,
      );
    }
  }

  void _showClientPicker(List<UserModel> clients) {
    showDialog(
      context: context,
      builder: (context) => SearchableClientPicker(
        clients: clients,
        selectedClientId: _selectedClientId,
        onClientSelected: (client) {
          setState(() {
            _selectedClientId = client.id;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء عقد جديد'),
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
          } else if (state is ContractCreatedSuccessfully) {
            Navigator.pop(context, true); // Close screen
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === Client Selector ===
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

                    final selectedClient = _selectedClientId != null
                        ? clients
                              .where((c) => c.id == _selectedClientId)
                              .firstOrNull
                        : null;

                    return InkWell(
                      onTap: () {
                        _showClientPicker(clients);
                      },
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceM,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gray400),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: _selectedClientId != null
                                  ? AppColors.primary
                                  : AppColors.gray500,
                            ),
                            const SizedBox(width: Dimensions.spaceM),
                            Expanded(
                              child: Text(
                                selectedClient?.fullName != null
                                    ? '${selectedClient!.fullName} (${selectedClient.email})'
                                    : 'اختر العميل',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedClientId != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.gray500,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

                    final selectedProject = _selectedProjectId != null
                        ? projects
                              .where((p) => p.id == _selectedProjectId)
                              .firstOrNull
                        : null;

                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SearchableProjectPicker(
                            projects: projects,
                            selectedProjectId: _selectedProjectId,
                            onProjectSelected: (project) {
                              setState(() {
                                _selectedProjectId = project.id;
                              });
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceM,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gray400),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: _selectedProjectId != null
                                  ? AppColors.primary
                                  : AppColors.gray500,
                            ),
                            const SizedBox(width: Dimensions.spaceM),
                            Expanded(
                              child: Text(
                                selectedProject?.name ??
                                    'اختر المشروع (اختياري)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedProjectId != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.gray500,
                            ),
                          ],
                        ),
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

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contractNumberController,
                        decoration: const InputDecoration(
                          labelText: 'رقم العقد',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.tag),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _generateContractNumber,
                      tooltip: 'توليد رقم جديد',
                    ),
                  ],
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
                    if (state is ContractsManagementCreating) {
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
                        'حفظ العقد',
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
