// lib/presentation/screens/handover/handover_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/defect_model.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/repositories/handover_repository.dart';
import 'package:mmm/presentation/cubits/defects/defects_cubit.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart';

class HandoverDetailScreen extends StatelessWidget {
  final HandoverModel handover;

  const HandoverDetailScreen({super.key, required this.handover});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DefectsCubit(repository: HandoverRepository())
            ..loadDefects(handover.id),
      child: _HandoverDetailView(handover: handover),
    );
  }
}

class _HandoverDetailView extends StatelessWidget {
  final HandoverModel handover;

  const _HandoverDetailView({required this.handover});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل التسليم'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        children: [
          // Status Card
          _buildStatusCard(),
          const SizedBox(height: Dimensions.spaceL),

          // Schedule Info
          _buildDetailsCard('معلومات الموعد', [
            if (handover.scheduledDate != null)
              _buildDetailRow(
                'الموعد المجدول',
                DateFormat('yyyy-MM-dd HH:mm').format(handover.scheduledDate!),
              ),
            if (handover.actualDate != null)
              _buildDetailRow(
                'تاريخ التسليم الفعلي',
                DateFormat('yyyy-MM-dd HH:mm').format(handover.actualDate!),
              ),
            if (handover.inspectionNotes != null)
              _buildDetailRow('ملاحظات الفحص', handover.inspectionNotes!),
          ]),

          const SizedBox(height: Dimensions.spaceL),

          // Defects Section
          BlocBuilder<DefectsCubit, DefectsState>(
            builder: (context, state) {
              if (state is DefectsLoaded) {
                return _buildDefectsSection(context, state);
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Timeline
          _buildTimelineCard(),

          const SizedBox(height: Dimensions.space3XL),

          // Action Buttons
          if (handover.status == HandoverStatus.scheduled)
            PrimaryButton.withIcon(
              text: 'حجز موعد',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.bookAppointment,
                  arguments: handover.id,
                );
              },
              icon: Icons.calendar_today,
            ),

          if (handover.status == HandoverStatus.inspectionPending) ...[
            PrimaryButton(
              text: 'الإبلاغ عن مشكلة',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.snagList,
                  arguments: handover.id,
                );
              },
            ),
            const SizedBox(height: Dimensions.spaceM),
            PrimaryButton(
              text: 'التوقيع على التسليم',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.signHandover,
                  arguments: handover.id,
                );
              },

              backgroundColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (handover.status) {
      case HandoverStatus.scheduled:
        statusColor = AppColors.warning;
        statusText = 'مجدولة';
        statusIcon = Icons.schedule;
        break;
      case HandoverStatus.inspectionPending:
      case HandoverStatus.defectsSubmitted:
      case HandoverStatus.defectsFixing:
        statusColor = AppColors.primary;
        statusText = 'جارية';
        statusIcon = Icons.timelapse;
        break;
      case HandoverStatus.readyForHandover:
        statusColor = AppColors.info;
        statusText = 'جاهزة';
        statusIcon = Icons.done_all;
        break;
      case HandoverStatus.completed:
        statusColor = AppColors.success;
        statusText = 'مكتملة';
        statusIcon = Icons.check_circle;
        break;
      case HandoverStatus.appointmentBooked:
        statusColor = AppColors.warning;
        statusText = 'تم حجز الموعد';
        statusIcon = Icons.event_available;
        break;
      case HandoverStatus.notStarted:
        statusColor = AppColors.success;
        statusText = 'مكتملة';
        statusIcon = Icons.check_circle;
        break;
      case HandoverStatus.inProgress:
        statusColor = AppColors.success;
        statusText = 'جاري';
        statusIcon = Icons.check_circle;
        break;
      case HandoverStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'ملغاة';
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: Dimensions.spaceL),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectsSection(BuildContext context, DefectsLoaded state) {
    return _buildDetailsCard('المشاكل المبلغ عنها', [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDefectStat('معلقة', state.pendingCount, AppColors.warning),
          _buildDefectStat('تم الإصلاح', state.fixedCount, AppColors.success),
          _buildDefectStat('الإجمالي', state.defects.length, AppColors.primary),
        ],
      ),
      if (state.defects.isNotEmpty) ...[
        const Divider(height: Dimensions.spaceL * 2),
        ...state.defects
            .take(3)
            .map(
              (defect) => Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spaceM),
                child: Row(
                  children: [
                    Icon(
                      defect.status == DefectStatus.fixed
                          ? Icons.check_circle
                          : Icons.error,
                      size: 16,
                      color: defect.status == DefectStatus.fixed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: Dimensions.spaceS),
                    Expanded(
                      child: Text(
                        defect.description,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    ]);
  }

  Widget _buildDefectStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الجدول الزمني',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),
          _buildTimelineItem(
            'تم الإنشاء',
            DateFormat('yyyy-MM-dd').format(handover.createdAt),
            true,
          ),
          if (handover.scheduledDate != null)
            _buildTimelineItem(
              'موعد مجدول',
              DateFormat('yyyy-MM-dd').format(handover.scheduledDate!),
              handover.actualDate != null,
            ),
          if (handover.actualDate != null)
            _buildTimelineItem(
              'تم التسليم',
              DateFormat('yyyy-MM-dd').format(handover.actualDate!),
              true,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String date, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isCompleted ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
