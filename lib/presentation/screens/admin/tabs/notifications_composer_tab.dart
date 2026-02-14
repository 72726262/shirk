import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/widgets/primary_button.dart';

class NotificationsComposerTab extends StatefulWidget {
  const NotificationsComposerTab({super.key});

  @override
  State<NotificationsComposerTab> createState() =>
      _NotificationsComposerTabState();
}

class _NotificationsComposerTabState extends State<NotificationsComposerTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleArController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyArController = TextEditingController();

  String _targetType = 'all'; // all, project, users

  // Selection State
  ProjectModel? _selectedProject;
  List<UserModel> _selectedUsers = [];

  String _priority = 'normal';

  @override
  void dispose() {
    _titleController.dispose();
    _titleArController.dispose();
    _bodyController.dispose();
    _bodyArController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminNotificationsCubit, AdminNotificationsState>(
      listener: (context, state) {
        if (state is AdminNotificationsSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال الإشعار بنجاح')),
          );
          _clearForm();
        } else if (state is AdminNotificationsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ: ${state.message}')));
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إنشاء إشعار جديد',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Dimensions.spaceL),

              // Target Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إرسال إلى:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Wrap(
                        spacing: Dimensions.spaceM,
                        children: [
                          _buildRadio('عام (الكل)', 'all'),
                          _buildRadio('مشروع محدد', 'project'),
                          _buildRadio('مستخدمين محددين', 'users'),
                        ],
                      ),
                      const Divider(),
                      if (_targetType == 'project') _buildProjectSelector(),
                      if (_targetType == 'users') _buildUserSelector(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spaceL),

              // Content
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'محتوى الإشعار',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _titleArController,
                              decoration: const InputDecoration(
                                labelText: 'العنوان (عربي)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'مطلوب' : null,
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceM),
                          Expanded(
                            child: TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Title (English)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title_outlined),
                              ),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      TextFormField(
                        controller: _bodyArController,
                        decoration: const InputDecoration(
                          labelText: 'نص الإشعار (عربي)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          labelText: 'Notification Body (English)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spaceL),

              // Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الإعدادات',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'الأولوية',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('عادية'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('عالية (عاجل)'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _priority = val!),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.spaceXL),

              BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
                builder: (context, state) {
                  return PrimaryButton(
                    text: 'إرسال الإشعار',
                    isLoading: state is AdminNotificationsSending,
                    onPressed: _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _targetType,
          onChanged: (val) {
            setState(() {
              _targetType = val!;
              // Reset selections when switching types
              if (_targetType != 'project') _selectedProject = null;
              if (_targetType != 'users') _selectedUsers = [];
            });
          },
        ),
        Text(label),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProjectSelector() {
    return InkWell(
      onTap: () => _showProjectSelectionDialog(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'المشروع المستهدف',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _selectedProject?.nameAr ?? 'اختر المشروع',
          style: TextStyle(
            color: _selectedProject == null
                ? Colors.grey
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showUserSelectionDialog(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'المستخدمين المستهدفين',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.person_search),
            ),
            child: Text(
              _selectedUsers.isEmpty
                  ? 'اختر المستخدمين'
                  : '${_selectedUsers.length} مستخدم محدد',
              style: TextStyle(
                color: _selectedUsers.isEmpty
                    ? Colors.grey
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        if (_selectedUsers.isNotEmpty) ...[
          const SizedBox(height: Dimensions.spaceS),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedUsers
                .map(
                  (u) => Chip(
                    label: Text(u.fullName.toString()),
                    onDeleted: () {
                      setState(() {
                        _selectedUsers.remove(u);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  void _showProjectSelectionDialog(BuildContext context) {
    final projectsCubit = context.read<ProjectsCubit>();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: StatefulBuilder(
            builder: (context, setStateBuilder) {
              return Padding(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Column(
                  children: [
                    Text(
                      'اختر المشروع',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'بحث باسم المشروع...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setStateBuilder(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    Expanded(
                      child: BlocBuilder<ProjectsCubit, ProjectsState>(
                        bloc: projectsCubit, // Explicitly pass the cubit
                        builder: (context, state) {
                          if (state is ProjectsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is ProjectsLoaded) {
                            var filteredProjects = state.projects;
                            if (searchQuery.isNotEmpty) {
                              filteredProjects = state.projects
                                  .where(
                                    (p) =>
                                        p.nameAr.toLowerCase().contains(
                                          searchQuery.toLowerCase(),
                                        ) ||
                                        (p.nameAr.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ) ??
                                            false),
                                  )
                                  .toList();
                            }

                            if (filteredProjects.isEmpty) {
                              return const Center(child: Text('لا توجد نتائج'));
                            }

                            return ListView.builder(
                              itemCount: filteredProjects.length,
                              itemBuilder: (context, index) {
                                final project = filteredProjects[index];
                                return ListTile(
                                  title: Text(project.nameAr),
                                  subtitle: Text(project.location ?? ''),
                                  selected: _selectedProject?.id == project.id,
                                  onTap: () {
                                    setState(() => _selectedProject = project);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          }
                          return const Center(child: Text('لا توجد مشاريع'));
                        },
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showUserSelectionDialog(BuildContext context) {
    // We need a local state for the search query and selection
    // Using a separate StatefulWidget implementation inside the dialog via StatefulBuilder
    String searchQuery = '';

    // Trigger load if empty (optional, assuming already loaded by parent screen)
    final clientCubit = context.read<ClientManagementCubit>();
    clientCubit.loadClients();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: StatefulBuilder(
            builder: (context, setStateBuilder) {
              return Padding(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Column(
                  children: [
                    Text(
                      'اختر المستخدمين',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Dimensions.spaceM),

                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'بحث باسم العميل...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setStateBuilder(() => searchQuery = val);
                      },
                    ),
                    const SizedBox(height: Dimensions.spaceM),

                    Expanded(
                      child:
                          BlocBuilder<
                            ClientManagementCubit,
                            ClientManagementState
                          >(
                            bloc: clientCubit, // Use captured cubit instance
                            builder: (context, state) {
                              if (state is ClientManagementLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (state is ClientManagementLoaded) {
                                var filteredClients = state.clients;
                                if (searchQuery.isNotEmpty) {
                                  filteredClients = state.clients
                                      .where(
                                        (c) =>
                                            c.fullName
                                                .toString()
                                                .toLowerCase()
                                                .contains(
                                                  searchQuery.toLowerCase(),
                                                ) ||
                                            c.email.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ),
                                      )
                                      .toList();
                                }

                                return ListView.builder(
                                  itemCount: filteredClients.length,
                                  itemBuilder: (context, index) {
                                    final client = filteredClients[index];
                                    final isSelected = _selectedUsers.any(
                                      (u) => u.id == client.id,
                                    );

                                    return CheckboxListTile(
                                      value: isSelected,
                                      title: Text(client.fullName.toString()),
                                      subtitle: Text(client.email),
                                      onChanged: (bool? value) {
                                        setStateBuilder(() {
                                          // Update local UI state if needed, but we rely on parent _selectedUsers
                                        });
                                        // Update parent state
                                        this.setState(() {
                                          if (value == true) {
                                            _selectedUsers.add(client);
                                          } else {
                                            _selectedUsers.removeWhere(
                                              (u) => u.id == client.id,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  },
                                );
                              }
                              return const Center(
                                child: Text('لا يوجد مستخدمين'),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('تم اختيار ${_selectedUsers.length}'),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('تم'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    String? userId;
    List<String>? userIds;
    String? projectId;

    if (_targetType == 'project') {
      if (_selectedProject == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار المشروع')));
        return;
      }
      projectId = _selectedProject!.id;
    } else if (_targetType == 'users') {
      if (_selectedUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار مستخدم واحد على الأقل')),
        );
        return;
      }
      // If one user, send as single (optional optimization, but Repository handles both)
      // actually Repository logic: if userId != null -> single. if userIds != null -> multiple.
      userIds = _selectedUsers.map((u) => u.id).toList();
    }

    // "all" target means userId=null, projectId=null, userIds=null -> Repository handles as Broadcast

    context.read<AdminNotificationsCubit>().sendNotification(
      title: _titleController.text,
      titleAr: _titleArController.text,
      body: _bodyController.text,
      bodyAr: _bodyArController.text,
      priority: _priority,
      projectId: projectId,
      userId: userId, // Legacy single user (null)
      userIds: userIds, // New multi user list
    );
  }

  void _clearForm() {
    _titleController.clear();
    _titleArController.clear();
    _bodyController.clear();
    _bodyArController.clear();
    setState(() {
      _targetType = 'all';
      _selectedProject = null;
      _selectedUsers = [];
      _priority = 'normal';
    });
  }
}
