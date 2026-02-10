import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/handover/handover_state.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/data/models/handover_model.dart';
import 'package:mmm/routes/route_names.dart';

class HandoverStatusScreen extends StatefulWidget {
  final String? unitId;

  const HandoverStatusScreen({super.key, this.unitId});

  @override
  State<HandoverStatusScreen> createState() => _HandoverStatusScreenState();
}

class _HandoverStatusScreenState extends State<HandoverStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.unitId != null) {
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.read<HandoverCubit>().loadHandoverStatus(widget.unitId!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حالة التسليم'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<HandoverCubit, HandoverState>(
        builder: (context, state) {
          if (state is HandoverLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HandoverStatusLoaded) {
            final data = state.data;
            final statusString = data['status'] as String? ?? 'not_started';
            final status = HandoverStatus.fromJson(statusString);

            return RefreshIndicator(
              onRefresh: () async {
                if (widget.unitId != null) {
                  await context.read<HandoverCubit>().refreshHandoverStatus(
                    widget.unitId!,
                  );
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.spaceXXL),
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceXL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Dimensions.radiusXL),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          status == HandoverStatus.completed
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 60,
                          color: AppColors.white,
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        Text(
                          status.displayName,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // Action Buttons
                  if (status == HandoverStatus.scheduled ||
                      status == HandoverStatus.notStarted)
                    PrimaryButton(
                      text: 'حجز موعد المعاينة',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.bookAppointment,
                        arguments: widget.unitId,
                      ),
                      leadingIcon: Icons.calendar_today,
                    ),
                  if (status == HandoverStatus.inspectionPending ||
                      status == HandoverStatus.appointmentBooked)
                    PrimaryButton(
                      text: 'قائمة العيوب',
                      onPressed: () => Navigator.pushNamed(
                        context,
                        RouteNames.snagList,
                        arguments: widget.unitId,
                      ),
                      leadingIcon: Icons.list_alt,
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
