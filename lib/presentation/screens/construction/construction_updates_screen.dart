import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/models/subscription_model.dart';
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:mmm/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ConstructionUpdatesScreen extends StatefulWidget {
  final String projectId;

  const ConstructionUpdatesScreen({super.key, required this.projectId});

  @override
  State<ConstructionUpdatesScreen> createState() =>
      _ConstructionUpdatesScreenState();
}

class _ConstructionUpdatesScreenState extends State<ConstructionUpdatesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ConstructionCubit>().loadUpdates(widget.projectId);
  }

  SubscriptionModel? _findSubscription(BuildContext context) {
    // Try to find subscription from DashboardCubit first as it's likely loaded
    final dashboardState = context.read<DashboardCubit>().state;
    if (dashboardState is DashboardLoaded) {
      try {
        return dashboardState.mySubscriptions.firstWhere(
          (s) => s.project?.id == widget.projectId,
        );
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final subscription = _findSubscription(context);
    final project = subscription?.project;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ConstructionCubit, ConstructionState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              // 1. Premium Sliver App Bar
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    project?.name ?? 'تحديثات المشروع',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (project?.imageUrl != null)
                        Image.network(
                          project!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
                        )
                      else
                        Container(color: AppColors.primary),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Unit Info Section (My Unit)
              if (subscription != null && subscription.unit != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    child: _buildUnitInfoCard(subscription),
                  ),
                ),

              // 3. Updates List
              if (state is ConstructionLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is ConstructionError)
                 SliverFillRemaining(
                  child: Center(child: Text(state.message)),
                )
              else if (state is ConstructionLoaded)
                if (state.updates.isEmpty)
                   const SliverFillRemaining(
                    child: Center(child: Text('لا توجد تحديثات حتى الآن')),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final update = state.updates[index];
                        final isLast = index == state.updates.length - 1;
                        return _buildTimelineItem(update, isLast);
                      },
                      childCount: state.updates.length,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnitInfoCard(SubscriptionModel subscription) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_outlined, color: AppColors.primary),
              const SizedBox(width: Dimensions.spaceS),
              const Text(
                'وحدتي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'رقم ${subscription.unit?.unitNumber ?? "-"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem('الدور', subscription.unit?.floor?.toString() ?? '-'),
              _buildInfoItem('المساحة', '${subscription.unit?.areaSqm ?? "-"} م²'),
              _buildInfoItem('الغرف', subscription.unit?.bedrooms?.toString() ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(ConstructionUpdateModel update, bool isLast) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.spaceL),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline Line & Dot
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getTypeColor(update.type),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _getTypeColor(update.type).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Dimensions.spaceM),
            
            // Content Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.spaceXL),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceM),
                        decoration: BoxDecoration(
                          color: _getTypeColor(update.type).withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(Dimensions.radiusL),
                            topRight: Radius.circular(Dimensions.radiusL),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              update.displayTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd MMM yyyy').format(update.updateDate ?? update.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(Dimensions.spaceM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           if (update.displayDescription != null) ...[
                              Text(
                                update.displayDescription!,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                              const SizedBox(height: Dimensions.spaceM),
                           ],

                           // Progress
                           if (update.progressPercentage != null) ...[
                             Row(
                               children: [
                                 Expanded(
                                   child: ClipRRect(
                                     borderRadius: BorderRadius.circular(4),
                                     child: LinearProgressIndicator(
                                       value: update.progress,
                                       backgroundColor: AppColors.gray100,
                                       valueColor: AlwaysStoppedAnimation(_getTypeColor(update.type)),
                                       minHeight: 6,
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 8),
                                 Text(
                                   '${update.progressPercentage!.toInt()}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getTypeColor(update.type),
                                      fontSize: 12,
                                    ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: Dimensions.spaceM),
                           ],

                           // Images
                           if (update.photos.isNotEmpty)
                             SizedBox(
                               height: 100,
                               child: ListView.builder(
                                 scrollDirection: Axis.horizontal,
                                 itemCount: update.photos.length,
                                 itemBuilder: (context, index) {
                                   return GestureDetector(
                                     onTap: () => _showFullImage(context, update.photos[index]),
                                     child: Container(
                                       width: 100,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: NetworkImage(update.photos[index]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                     ),
                                   );
                                 },
                               ),
                             ),

                           // Reports Links
                           if (update.engineeringReportUrl != null || update.financialReportUrl != null) ...[
                              const SizedBox(height: Dimensions.spaceM),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (update.engineeringReportUrl != null)
                                      _buildReportButton('تقرير هندسي', update.engineeringReportUrl!),
                                    const SizedBox(width: 8),
                                    if (update.financialReportUrl != null)
                                      _buildReportButton('تقرير مالي', update.financialReportUrl!),
                                  ],
                                ),
                              ),
                           ]
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(String label, String url) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
             const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
     showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(child: Image.network(url)),
      ),
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
