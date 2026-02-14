import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_cubit.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:intl/intl.dart';
import 'package:mmm/presentation/screens/admin/screens/create_handover_screen.dart';

import '../../../cubits/admin/handovers_management_state.dart';

class HandoversManagementTab extends StatefulWidget {
  const HandoversManagementTab({super.key});

  @override
  State<HandoversManagementTab> createState() => _HandoversManagementTabState();
}

class _HandoversManagementTabState extends State<HandoversManagementTab> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<HandoversManagementCubit>().loadHandovers();
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
              builder: (context) => const CreateHandoverScreen(),
            ),
          );

          if (result == true && mounted) {
            context.read<HandoversManagementCubit>().loadHandovers();
          }
        },
        label: const Text('إنشاء تسليم'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child:
                BlocConsumer<
                  HandoversManagementCubit,
                  HandoversManagementState
                >(
                  listener: (context, state) {
                    if (state is HandoversManagementError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    } else if (state is HandoverCompletedSuccessfully) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم إتمام التسليم بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.read<HandoversManagementCubit>().loadHandovers();
                    } else if (state is HandoverUpdatedSuccessfully) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث التسليم بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.read<HandoversManagementCubit>().loadHandovers();
                    } else if (state is HandoverDeletedSuccessfully) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حذف التسليم بنجاح'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.read<HandoversManagementCubit>().loadHandovers();
                    }
                  },
                  builder: (context, state) {
                    if (state is HandoversManagementLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is HandoversManagementLoaded) {
                      return _buildHandoversTable(state.handovers);
                    }

                    return const Center(child: Text('لا توجد عمليات تسليم'));
                  },
                ),
          ),
        ],
      ),
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
                      context.read<HandoversManagementCubit>().loadHandovers();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('معلق'),
                  selected: _selectedStatus == 'notStarted',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'notStarted');
                      context.read<HandoversManagementCubit>().loadHandovers(
                        status: 'notStarted',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('مجدول'),
                  selected: _selectedStatus == 'scheduled',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'scheduled');
                      context.read<HandoversManagementCubit>().loadHandovers(
                        status: 'scheduled',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('قيد الفحص'),
                  selected: _selectedStatus == 'inspectionPending',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'inspectionPending');
                      context.read<HandoversManagementCubit>().loadHandovers(
                        status: 'inspectionPending',
                      );
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('مكتمل'),
                  selected: _selectedStatus == 'completed',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = 'completed');
                      context.read<HandoversManagementCubit>().loadHandovers(
                        status: 'completed',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoversTable(List<HandoverModel> handovers) {
    if (handovers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key, size: 64, color: AppColors.textSecondary),
            SizedBox(height: Dimensions.spaceM),
            Text('لا توجد عمليات تسليم'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        children: handovers.map((handover) {
          return _buildHandoverCard(handover);
        }).toList(),
      ),
    );
  }

  Widget _buildHandoverCard(HandoverModel handover) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'عملية تسليم #${handover.id.substring(0, 8)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildStatusChip(handover.status),
            const SizedBox(width: Dimensions.spaceS),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'edit') {
                   // Reuse CreateHandoverScreen for editing? Or create new one?
                   // For now, let's show a "Not Implemented" or better, navigate to Create screen with data
                   // But CreateScreen might not support editing mode yet.
                   // Let's implement delete first as it is easier.
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('تعديل التسليم قيد التطوير')),
                   );
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تأكيد الحذف'),
                      content: const Text(
                        'هل أنت متأكد من حذف عملية التسليم هذه؟\nسيتم حذف جميع العيوب المرتبطة بها.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                        TextButton(
                          onPressed: () {
                             context.read<HandoversManagementCubit>().deleteHandover(handover.id);
                             Navigator.pop(context);
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: Dimensions.spaceS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (handover.scheduledDate != null)
                Text(
                  'الموعد: ${DateFormat('dd/MM/yyyy HH:mm').format(handover.scheduledDate!)}',
                  style: const TextStyle(fontSize: 13),
                ),
              const SizedBox(height: Dimensions.spaceXS),
              Text(
                'تاريخ الإنشاء: ${DateFormat('dd/MM/yyyy').format(handover.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (handover.notes != null) ...[
                  const Text(
                    'ملاحظات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceXS),
                  Text(handover.notes!),
                  const SizedBox(height: Dimensions.spaceM),
                ],

                // Defects count
                if (handover.defectsCount != null &&
                    handover.defectsCount! > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: AppColors.warning),
                        const SizedBox(width: Dimensions.spaceS),
                        Text(
                          'يوجد ${handover.defectsCount} عيوب مسجلة',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _viewDefects(handover.id),
                          child: const Text('عرض العيوب'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                ],

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (handover.status != HandoverStatus.completed) ...[
                      OutlinedButton.icon(
                        onPressed: () => _rescheduleAppointment(handover),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('إعادة جدولة'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _completeHandover(handover.id),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('إتمام التسليم'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                    if (handover.status == HandoverStatus.completed)
                      OutlinedButton.icon(
                        onPressed: () => _generateCertificate(handover.id),
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('إصدار شهادة'),
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

  Widget _buildStatusChip(HandoverStatus status) {
    Color color;
    String label;

    switch (status) {
      case HandoverStatus.scheduled:
      case HandoverStatus.notStarted:
        color = AppColors.textSecondary;
        label = 'معلق';
        break;
      case HandoverStatus.appointmentBooked:
        color = AppColors.primary;
        label = 'مجدول';
        break;
      case HandoverStatus.inspectionPending:
      case HandoverStatus.inProgress:
        color = AppColors.warning;
        label = 'قيد الفحص';
        break;
      case HandoverStatus.defectsSubmitted:
      case HandoverStatus.defectsFixing:
        color = Colors.orange;
        label = 'إصلاح العيوب';
        break;
      case HandoverStatus.readyForHandover:
      case HandoverStatus.completed:
        color = AppColors.success;
        label = 'مكتمل';
        break;
      case HandoverStatus.cancelled:
        color = AppColors.error;
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
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  void _viewDefects(String handoverId) {
    // Navigate to defects screen or show dialog
    context.read<HandoversManagementCubit>().loadDefects(handoverId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('العيوب المسجلة'),
        content:
            BlocBuilder<HandoversManagementCubit, HandoversManagementState>(
              builder: (context, state) {
                if (state is DefectsLoaded) {
                  return SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: ListView.builder(
                      itemCount: state.defects.length,
                      itemBuilder: (context, index) {
                        final defect = state.defects[index];
                        return ListTile(
                          title: Text(defect.description),
                          subtitle: Text(
                            'الخطورة: ${_getSeverityLabel(defect.severity)}',
                          ),
                          trailing: _buildDefectStatusChip(defect.status),
                        );
                      },
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
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

  Widget _buildDefectStatusChip(DefectStatus status) {
    Color color;
    String label;

    switch (status) {
      case DefectStatus.pending:
      case DefectStatus.acknowledged:
        color = AppColors.warning;
        label = 'معلق';
        break;
      case DefectStatus.fixing:
        color = AppColors.primary;
        label = 'قيد الإصلاح';
        break;
      case DefectStatus.fixed:
      case DefectStatus.closed:
        color = AppColors.success;
        label = 'تم الإصلاح';
        break;
      case DefectStatus.rejected:
        color = AppColors.error;
        label = 'مرفوض';
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
      child: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  String _getSeverityLabel(DefectSeverity severity) {
    switch (severity) {
      case DefectSeverity.low:
        return 'بسيط';
      case DefectSeverity.medium:
        return 'متوسط';
      case DefectSeverity.high:
        return 'كبير';
      case DefectSeverity.critical:
        return 'حرج';
    }
  }

  void _rescheduleAppointment(HandoverModel handover) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة جدولة الموعد'),
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

  void _completeHandover(String handoverId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إتمام التسليم'),
        content: const Text(
          'هل أنت متأكد من إتمام عملية التسليم؟\nملاحظة: يتطلب توقيع العميل',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement signature collection before completing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يجب إضافة توقيع العميل أولاً'),
                  backgroundColor: AppColors.warning,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _generateCertificate(String handoverId) {
    context.read<HandoversManagementCubit>().generateHandoverCertificate(
      handoverId,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري إصدار الشهادة...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
