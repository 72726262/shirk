import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';

import 'package:mmm/presentation/cubits/admin/handovers_management_state.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_cubit.dart';
import 'package:mmm/presentation/widgets/dialogs/searchable_project_picker.dart';
import 'package:mmm/presentation/widgets/dialogs/searchable_client_picker.dart';
import 'package:intl/intl.dart';

class CreateHandoverScreen extends StatefulWidget {
  const CreateHandoverScreen({super.key});

  @override
  State<CreateHandoverScreen> createState() => _CreateHandoverScreenState();
}

class _CreateHandoverScreenState extends State<CreateHandoverScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedProjectId;
  String? _selectedSubscriptionId;

  final _appointmentDateController = TextEditingController();
  final _appointmentLocationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedAppointmentDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load data
    context.read<ClientManagementCubit>().loadClients();
    context.read<ProjectsCubit>().loadProjects();
  }

  @override
  void dispose() {
    _appointmentDateController.dispose();
    _appointmentLocationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId == null || _selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار العميل والمشروع'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_selectedSubscriptionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على اشتراك لهذا العميل في المشروع المحدد'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_selectedAppointmentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار تاريخ الموعد'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      context.read<HandoversManagementCubit>().createHandover(
        userId: _selectedClientId!,
        projectId: _selectedProjectId!,
        subscriptionId: _selectedSubscriptionId,
        appointmentDate: _selectedAppointmentDate!,
        appointmentLocation: _appointmentLocationController.text.isNotEmpty
            ? _appointmentLocationController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
    }
  }

  void _selectAppointmentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (time != null) {
        setState(() {
          _selectedAppointmentDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _appointmentDateController.text = DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(_selectedAppointmentDate!);
        });
      }
    }
  }

  // Check for existing subscription
  Future<void> _checkSubscription() async {
    if (_selectedClientId != null && _selectedProjectId != null) {
      setState(() => _isLoading = true);
      
      final subId = await context
          .read<HandoversManagementCubit>()
          .getSubscriptionId(_selectedClientId!, _selectedProjectId!);
      
      if (mounted) {
        setState(() {
          _selectedSubscriptionId = subId;
          _isLoading = false;
        });
        
        if (subId == null && !context.mounted) return;
        
        if (subId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تنبيه: هذا العميل ليس لديه اشتراك في هذا المشروع'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
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
            _selectedSubscriptionId = null; // Reset subscription
          });
          Navigator.pop(context);
          _checkSubscription();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء عملية تسليم جديدة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<HandoversManagementCubit, HandoversManagementState>(
        listener: (context, state) {
          if (state is HandoversManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is HandoverCreatedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إنشاء عملية التسليم بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true);
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
                      onTap: () => _showClientPicker(clients),
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
                              _checkSubscription();
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
                                selectedProject?.name ?? 'اختر المشروع',
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

                // === Appointment Date ===
                const Text(
                  'موعد التسليم',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: Dimensions.spaceS),
                InkWell(
                  onTap: _selectAppointmentDate,
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceM,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray400),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _selectedAppointmentDate != null
                              ? AppColors.primary
                              : AppColors.gray500,
                        ),
                        const SizedBox(width: Dimensions.spaceM),
                        Expanded(
                          child: Text(
                            _appointmentDateController.text.isNotEmpty
                                ? _appointmentDateController.text
                                : 'اختر موعد التسليم',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedAppointmentDate != null
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
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Appointment Location ===
                TextFormField(
                  controller: _appointmentLocationController,
                  decoration: const InputDecoration(
                    labelText: 'مكان التسليم (اختياري)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // === Notes ===
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),

                // === Submit Button ===
                BlocBuilder<HandoversManagementCubit, HandoversManagementState>(
                  builder: (context, state) {
                    if (state is HandoversManagementCreating) {
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
                        'إنشاء عملية التسليم',
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
