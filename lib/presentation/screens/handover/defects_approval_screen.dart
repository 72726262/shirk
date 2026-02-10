import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';

class DefectsApprovalScreen extends StatefulWidget {
  final String unitId;

  const DefectsApprovalScreen({super.key, required this.unitId});

  @override
  State<DefectsApprovalScreen> createState() => _DefectsApprovalScreenState();
}

class _DefectsApprovalScreenState extends State<DefectsApprovalScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HandoverCubit>().loadDefectsForApproval(widget.unitId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الموافقة على إصلاح العيوب'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<HandoverCubit, HandoverState>(
        builder: (context, state) {
          if (state is HandoverLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DefectsLoaded) {
            final defects = state.defects;

            if (defects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    ),
                    SizedBox(height: Dimensions.spaceL),
                    Text(
                      'تم إصلاح جميع العيوب!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              itemCount: defects.length,
              itemBuilder: (context, index) {
                final defect = defects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    defect.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.spaceS),
                                  Text(
                                    defect.description,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.spaceM,
                                vertical: Dimensions.spaceS,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusM,
                                ),
                              ),
                              child: const Text(
                                'قيد المراجعة',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _rejectDefect(defect.id),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                ),
                                child: const Text(
                                  'رفض',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: Dimensions.spaceM),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                text: 'موافقة',
                                onPressed: () => _approveDefect(defect.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _approveDefect(String defectId) async {
    await context.read<HandoverCubit>().approveDefect(defectId);
  }

  Future<void> _rejectDefect(String defectId) async {
    await context.read<HandoverCubit>().rejectDefect(defectId);
  }
}
