import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/handover/handover_state.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/common/custom_text_field.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';

class SnagListScreen extends StatefulWidget {
  final String unitId;

  const SnagListScreen({super.key, required this.unitId});

  @override
  State<SnagListScreen> createState() => _SnagListScreenState();
}

class _SnagListScreenState extends State<SnagListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _images = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<HandoverCubit>().loadSnags(widget.unitId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('قائمة العيوب'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<HandoverCubit, HandoverState>(
        listener: (context, state) {
          if (state is SnagAdded) {
            _clearForm();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إضافة العيب بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is HandoverLoading;
          final snags = state is SnagsLoaded ? state.snags : [];

          return Column(
            children: [
              // Snag List
              Expanded(
                child: snags.isEmpty
                    ? const Center(child: Text('لا توجد عيوب مسجلة'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(Dimensions.spaceL),
                        itemCount: snags.length,
                        itemBuilder: (context, index) {
                          final snag = snags[index];
                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: Dimensions.spaceM,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(
                                  snag.status,
                                ).withValues(alpha: 0.1),
                                child: Icon(
                                  _getStatusIcon(snag.status),
                                  color: _getStatusColor(snag.status),
                                ),
                              ),
                              title: Text(snag.title),
                              subtitle: Text(snag.description),
                              trailing: Chip(
                                label: Text(
                                  snag.status,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: _getStatusColor(
                                  snag.status,
                                ).withValues(alpha: 0.1),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Add Snag Form
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'إضافة عيب جديد',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _titleController,
                              label: 'العنوان',
                              enabled: !isLoading,
                              validator: (v) =>
                                  v?.isEmpty ?? true ? 'مطلوب' : null,
                            ),
                            const SizedBox(height: Dimensions.spaceM),
                            CustomTextField(
                              controller: _descriptionController,
                              label: 'الوصف',
                              maxLines: 2,
                              enabled: !isLoading,
                            ),
                            const SizedBox(height: Dimensions.spaceM),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: isLoading ? null : _pickImages,
                                  icon: const Icon(Icons.camera_alt),
                                  label: Text('صور (${_images.length})'),
                                ),
                                const Spacer(),
                                Expanded(
                                  flex: 2,
                                  child: PrimaryButton(
                                    text: 'إضافة',
                                    onPressed: isLoading ? null : _addSnag,
                                    isLoading: isLoading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    setState(() => _images.addAll(images));
  }

  Future<void> _addSnag() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<HandoverCubit>().addSnag(
      unitId: widget.unitId,
      title: _titleController.text,
      description: _descriptionController.text,
      images: _images,
    );
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _images.clear();
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.error;
    }
  }
}
