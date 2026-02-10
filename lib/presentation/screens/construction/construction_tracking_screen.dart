import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

class ConstructionTrackingScreen extends StatefulWidget {
  final String projectId;

  const ConstructionTrackingScreen({super.key, required this.projectId});

  @override
  State<ConstructionTrackingScreen> createState() =>
      _ConstructionTrackingScreenState();
}

class _ConstructionTrackingScreenState
    extends State<ConstructionTrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ConstructionCubit>().loadUpdates(widget.projectId);
    context.read<ConstructionCubit>().subscribeToUpdates(
      widget.projectId,
    ); // REAL-TIME!
  }

  @override
  void dispose() {
    context.read<ConstructionCubit>().unsubscribeFromUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('متابعة البناء'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<ConstructionCubit, ConstructionState>(
        builder: (context, state) {
          if (state is ConstructionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConstructionLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ConstructionCubit>().refreshUpdates(
                  widget.projectId,
                );
              },
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.spaceXXL),
                children: [
                  // Progress Bar
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceXL),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'التقدم الإجمالي',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${state.overallProgress}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        LinearProgressIndicator(
                          value: state.overallProgress / 100,
                          minHeight: 10,
                          backgroundColor: AppColors.gray200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Updates List
                  ...state.updates.map(
                    (update) => Card(
                      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            '${update.progress}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(update.title),
                        subtitle: Text(update.description?.toString() ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
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
