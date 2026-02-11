import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/construction_update_model.dart';

import 'package:intl/intl.dart';

class ConstructionUpdatesTab extends StatefulWidget {
  final String userId;

  const ConstructionUpdatesTab({super.key, required this.userId});

  @override
  State<ConstructionUpdatesTab> createState() => _ConstructionUpdatesTabState();
}

class _ConstructionUpdatesTabState extends State<ConstructionUpdatesTab> {
  // TODO: Integrate with ConstructionService to fetch updates
  List<ConstructionUpdateModel> _updates = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _loadUpdates(); // TODO: Uncomment when service is ready
  }

  Future<void> _loadUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with actual service call
      // final updates = await _constructionService.getUserProjectUpdates(widget.userId);
      setState(() {
        // _updates = updates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديثات البناء'),
        backgroundColor: AppColors.primary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: Dimensions.spaceM),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: Dimensions.spaceM),
            ElevatedButton(
              onPressed: _loadUpdates,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_updates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: Dimensions.spaceM),
            Text('لا توجد تحديثات حالياً'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpdates,
      child: ListView.builder(
        padding: Dimensions.screenPadding,
        itemCount: _updates.length,
        itemBuilder: (context, index) {
          return _buildUpdateCard(_updates[index]);
        },
      ),
    );
  }

  Widget _buildUpdateCard(ConstructionUpdateModel update) {
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
                        update.titleAr.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildUpdateTypeChip(update.type.toString()),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceS),
                Text(
                  DateFormat(
                    'dd MMMM yyyy',
                    'ar',
                  ).format(update.updateDate as DateTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (update.descriptionAr != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceM,
              ),
              child: Text(
                update.descriptionAr!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          const SizedBox(height: Dimensions.spaceM),

          // Progress Bar
          if (update.progressPercentage != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'نسبة الإنجاز',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${update.progressPercentage!.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          const SizedBox(height: Dimensions.spaceM),

          // Photos
          if (update.photos.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceM,
                ),
                itemCount: update.photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: EdgeInsets.only(
                      left: index == update.photos.length - 1
                          ? 0
                          : Dimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      image: DecorationImage(
                        image: NetworkImage(update.photos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: Dimensions.spaceM),

          // Reports
          if (update.engineeringReportUrl != null ||
              update.financialReportUrl != null ||
              update.supervisionReportUrl != null)
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceM),
              child: Wrap(
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
                      Icons.money,
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
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateTypeChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'milestone':
        color = AppColors.success;
        label = 'إنجاز';
        break;
      case 'progress':
        color = AppColors.primary;
        label = 'تقدم';
        break;
      case 'delay':
        color = AppColors.warning;
        label = 'تأخير';
        break;
      case 'issue':
        color = AppColors.error;
        label = 'مشكلة';
        break;
      case 'completion':
        color = AppColors.info;
        label = 'اكتمال';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'عام';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceS,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportChip(String label, IconData icon, String url) {
    return InkWell(
      onTap: () {
        // TODO: Open report
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فتح $label')));
      },
      child: Chip(
        avatar: Icon(icon, size: 16, color: AppColors.primary),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: AppColors.primary.withOpacity(0.1),
      ),
    );
  }
}
