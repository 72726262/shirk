import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ConstructionUpdatesTab extends StatefulWidget {
  final String userId;

  const ConstructionUpdatesTab({super.key, required this.userId});

  @override
  State<ConstructionUpdatesTab> createState() => _ConstructionUpdatesTabState();
}

class _ConstructionUpdatesTabState extends State<ConstructionUpdatesTab> {
  @override
  void initState() {
    super.initState();
    // Load updates specific to the user's subscriptions
    context.read<ConstructionCubit>().loadUserUpdates(widget.userId);
  }

  Future<void> _refresh() async {
    await context.read<ConstructionCubit>().loadUserUpdates(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديثات البناء'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<ConstructionCubit, ConstructionState>(
        listener: (context, state) {
          if (state is ConstructionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConstructionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConstructionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: Dimensions.spaceM),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (state is ConstructionLoaded) {
            if (state.updates.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.construction_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    const Text('لا توجد تحديثات حالياً لمشاريعك'),
                    const SizedBox(height: Dimensions.spaceS),
                    Text(
                      'سنقوم بإعلامك فور توفر تحديثات جديدة',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: Dimensions.screenPadding,
                itemCount: state.updates.length,
                itemBuilder: (context, index) {
                  return _buildUpdateCard(state.updates[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUpdateCard(ConstructionUpdateModel update) {
    // Determine the type label and color
    // If update.type is an enum, we handle it. If likely it is just passed as is.

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        update.titleAr
                            .toString(), // Assuming localized title is what we want
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildUpdateTypeChip(update.type),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceXS),
                // Calculate if project name needs to be shown (if available in future metadata)
                // For now just date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: Dimensions.spaceXS),
                    Text(
                      DateFormat(
                        'dd MMMM yyyy',
                        'ar',
                      ).format(update.updateDate ?? update.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (update.weekNumber != null) ...[
                      const SizedBox(width: Dimensions.spaceM),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'الأسبوع ${update.weekNumber}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (update.descriptionAr != null &&
                    update.descriptionAr!.isNotEmpty) ...[
                  Text(
                    update.descriptionAr!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                ],

                // Progress Bar
                if (update.progressPercentage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'نسبة الإنجاز',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${update.progressPercentage!.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXS),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    child: LinearProgressIndicator(
                      value: update.progressPercentage! / 100,
                      backgroundColor: AppColors.gray200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.success,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                ],

                // Photos Gallery
                if (update.photos.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: update.photos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showFullImage(context, update.photos[index]);
                          },
                          child: Container(
                            width: 160,
                            margin: EdgeInsets.only(
                              left: index == update.photos.length - 1
                                  ? 0
                                  : Dimensions.spaceS,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(update.photos[index]),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                ],

                // Reports
                if (update.engineeringReportUrl != null ||
                    update.financialReportUrl != null ||
                    update.supervisionReportUrl != null) ...[
                  const Text(
                    'التقارير المرفقة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Wrap(
                    spacing: Dimensions.spaceS,
                    runSpacing: Dimensions.spaceS,
                    children: [
                      if (update.engineeringReportUrl != null)
                        _buildReportChip(
                          'تقرير هندسي',
                          Icons.engineering,
                          update.engineeringReportUrl!,
                        ),
                      if (update.financialReportUrl != null)
                        _buildReportChip(
                          'تقرير مالي',
                          Icons.account_balance,
                          update.financialReportUrl!,
                        ),
                      if (update.supervisionReportUrl != null)
                        _buildReportChip(
                          'تقرير إشرافي',
                          Icons.supervisor_account,
                          update.supervisionReportUrl!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateTypeChip(UpdateType type) {
    Color color;
    String label;

    switch (type) {
      case UpdateType.milestone:
        color = AppColors.success;
        label = 'إنجاز';
        break;
      case UpdateType.progress:
        color = AppColors.primary;
        label = 'تقدم';
        break;
      case UpdateType.delay:
        color = AppColors.error; // Changed to error for high visibility
        label = 'تأخير';
        break;
      case UpdateType.completion:
        color = Colors.purple;
        label = 'اكتمال';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'عام';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportChip(String label, IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط')));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.loose,
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
