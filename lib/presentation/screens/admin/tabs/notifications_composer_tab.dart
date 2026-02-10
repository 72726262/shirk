import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/widgets/primary_button.dart';

class NotificationsComposerTab extends StatefulWidget {
  const NotificationsComposerTab({super.key});

  @override
  State<NotificationsComposerTab> createState() => _NotificationsComposerTabState();
}

class _NotificationsComposerTabState extends State<NotificationsComposerTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleArController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyArController = TextEditingController();
  final _userIdController = TextEditingController(); // For specific user ID

  String _targetType = 'all'; // all, project, user
  String? _selectedProjectId;
  String _priority = 'normal';

  @override
  void dispose() {
    _titleController.dispose();
    _titleArController.dispose();
    _bodyController.dispose();
    _bodyArController.dispose();
    _userIdController.dispose();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${state.message}')),
          );
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
              const Text('إرسال إلى:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildRadio('الكل (مستخدمين)', 'all'),
                  _buildRadio('مشروع محدد', 'project'),
                  _buildRadio('مستخدم محدد', 'user'),
                ],
              ),
              
              if (_targetType == 'project')
                BlocBuilder<ProjectsCubit, ProjectsState>(
                  builder: (context, state) {
                    List<DropdownMenuItem<String>> items = [];
                    if (state is ProjectsLoaded) {
                      items = state.projects.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nameAr),
                      )).toList();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.spaceM),
                      child: DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        items: items,
                        decoration: const InputDecoration(
                          labelText: 'اختر المشروع',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => setState(() => _selectedProjectId = val),
                        validator: (v) => v == null ? 'مطلوب' : null,
                      ),
                    );
                  },
                ),
              
              if (_targetType == 'user')
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.spaceM),
                  child: TextFormField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      labelText: 'معرف المستخدم (User ID)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                  ),
                ),
                
              const SizedBox(height: Dimensions.spaceM),
              
              // Content
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _titleArController,
                      decoration: const InputDecoration(
                        labelText: 'العنوان (عربي)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title (English)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
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
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              
              const SizedBox(height: Dimensions.spaceM),
              
              // Priority
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'الأولوية',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('عادية')),
                  DropdownMenuItem(value: 'high', child: Text('عالية')),
                ],
                onChanged: (val) => setState(() => _priority = val!),
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
      children: [
        Radio<String>(
          value: value,
          groupValue: _targetType,
          onChanged: (val) => setState(() => _targetType = val!),
        ),
        Text(label),
        const SizedBox(width: 8),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    // Implement submit logic
    context.read<AdminNotificationsCubit>().sendNotification(
      title: _titleController.text,
      titleAr: _titleArController.text,
      body: _bodyController.text,
      bodyAr: _bodyArController.text,
      priority: _priority,
      projectId: _targetType == 'project' ? _selectedProjectId : null,
      userId: _targetType == 'user' ? _userIdController.text : null,
    );
  }
  
  void _clearForm() {
    _titleController.clear();
    _titleArController.clear();
    _bodyController.clear();
    _bodyArController.clear();
    _userIdController.clear();
    setState(() {
      _targetType = 'all';
      _selectedProjectId = null;
      _priority = 'normal';
    });
  }
}
