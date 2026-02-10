// lib/presentation/screens/handover/handovers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/data/services/handover_service.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';
import 'package:mmm/presentation/cubits/handover/handover_state.dart';
import 'package:mmm/presentation/screens/handover/handover_detail_screen.dart';
import 'package:intl/intl.dart';

class HandoversScreen extends StatelessWidget {
  const HandoversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = HandoverCubit(handoverService: HandoverService());
        final authState = context.read<AuthCubit>().state;
        if (authState is Authenticated) {
          cubit.loadUserHandovers(authState.user.id);
        }
        return cubit;
      },
      child: const _HandoversView(),
    );
  }
}

class _HandoversView extends StatelessWidget {
  const _HandoversView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التسليمات'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<HandoverCubit, HandoverState>(
        builder: (context, state) {
          if (state is HandoverLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HandoverError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: Dimensions.spaceL),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (state is HandoversListLoaded) {
            if (state.handovers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home_work,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text('لا توجد تسليمات'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                if (authState is Authenticated) {
                  await context.read<HandoverCubit>().loadUserHandovers(
                    authState.user.id,
                  );
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: state.handovers.length,
                itemBuilder: (context, index) {
                  final handover = state.handovers[index];
                  return _buildHandoverCard(context, handover);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHandoverCard(BuildContext context, HandoverModel handover) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (handover.status) {
      case HandoverStatus.scheduled:
      case HandoverStatus.notStarted:
      case HandoverStatus.appointmentBooked:
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
      case HandoverStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'ملغاة';
        statusIcon = Icons.cancel;
        break;
      case HandoverStatus.inProgress:
        statusColor = AppColors.primary;
        statusText = 'قيد التنفيذ';
        statusIcon = Icons.engineering;
        break;
      default:
        statusColor = Colors.grey;
        statusText = handover.status.name;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandoverDetailScreen(handover: handover),
            ),
          );
        },
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceS),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسليم وحدة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 13, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const Divider(height: Dimensions.spaceL * 2),
              if (handover.scheduledDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: Dimensions.spaceS),
                    Text(
                      'الموعد: ${DateFormat('yyyy-MM-dd HH:mm').format(handover.scheduledDate!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              if (handover.actualDate != null) ...[
                const SizedBox(height: Dimensions.spaceS),
                Row(
                  children: [
                    Icon(Icons.check, size: 16, color: AppColors.success),
                    const SizedBox(width: Dimensions.spaceS),
                    Text(
                      'تم التسليم: ${DateFormat('yyyy-MM-dd').format(handover.actualDate!)}',
                      style: TextStyle(fontSize: 13, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
