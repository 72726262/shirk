// lib/presentation/screens/construction/construction_updates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:intl/intl.dart';

class ConstructionUpdatesScreen extends StatelessWidget {
  final String projectId;

  const ConstructionUpdatesScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تحديثات المشروع'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<ConstructionCubit, ConstructionState>(
        builder: (context, state) {
          if (state is ConstructionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConstructionError) {
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

          if (state is ConstructionLoaded) {
            if (state.updates.isEmpty) {
              return const Center(child: Text('لا توجد تحديثات'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ConstructionCubit>().loadUpdates(projectId);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: state.updates.length,
                itemBuilder: (context, index) {
                  final update = state.updates[index];
                  return _buildUpdateCard(context, update);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, ConstructionUpdateModel update) {
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: _getTypeColor(update.type).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusM),
                topRight: Radius.circular(Dimensions.radiusM),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.spaceM,
                    vertical: Dimensions.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(update.type),
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                  child: Text(
                    update.type.displayName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (update.weekNumber != null)
                  Text(
                    'الأسبوع ${update.weekNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  update.displayTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (update.displayDescription != null) ...[
                  const SizedBox(height: Dimensions.spaceM),
                  Text(
                    update.displayDescription!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: Dimensions.spaceL),
                
                // Progress indicator
                if (update.progressPercentage != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: update.progress,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spaceM),
                      Text(
                        '${update.progressPercentage!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                ],

                // Photos gallery preview
                if (update.photos.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: update.photos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(left: Dimensions.spaceM),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusM),
                            image: DecorationImage(
                              image: NetworkImage(update.photos[index]),
                              fit: BoxFit.cover,
                              onError: (error, stackTrace) {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                ],

                // Reports
                if (update.engineeringReportUrl != null ||
                    update.financialReportUrl != null ||
                    update.supervisionReportUrl != null) ...[
                  const Divider(),
                  const SizedBox(height: Dimensions.spaceM),
                  Wrap(
                    spacing: Dimensions.spaceM,
                    runSpacing: Dimensions.spaceM,
                    children: [
                      if (update.engineeringReportUrl != null)
                        _buildReportChip('تقرير هندسي', Icons.engineering),
                      if (update.financialReportUrl != null)
                        _buildReportChip('تقرير مالي', Icons.account_balance),
                      if (update.supervisionReportUrl != null)
                        _buildReportChip('تقرير إشراف', Icons.supervisor_account),
                    ],
                  ),
                ],

                // Date
                const SizedBox(height: Dimensions.spaceM),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: Dimensions.spaceS),
                    Text(
                      DateFormat('yyyy-MM-dd').format(update.updateDate ?? update.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildReportChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primary.withOpacity(0.1),
    );
  }

  Color _getTypeColor(UpdateType type) {
    switch (type) {
      case UpdateType.milestone:
        return AppColors.success;
      case UpdateType.progress:
        return AppColors.primary;
      case UpdateType.delay:
        return AppColors.error;
      case UpdateType.completion:
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }
}
