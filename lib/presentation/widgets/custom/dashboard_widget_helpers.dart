import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/construction_update_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/routes/route_names.dart';

Widget _buildOverdueAlert(int count, double totalAmount, BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(Dimensions.spaceM),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.error.withOpacity(0.1),
          AppColors.error.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(Dimensions.radiusL),
      border: Border.all(color: AppColors.error.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber,
            color: AppColors.error,
            size: 24,
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أقساط متأخرة',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'لديك $count قسط متأخر بقيمة ${totalAmount.toStringAsFixed(2)} ر.س',
                style: TextStyle(fontSize: 13, color: AppColors.gray700),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pushNamed(context, RouteNames.installments),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('دفع الآن'),
        ),
      ],
    ),
  );
}

Widget _buildUnsignedDocumentsAlert(int count, BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(Dimensions.spaceM),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.warning.withOpacity(0.1),
          AppColors.warning.withOpacity(0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(Dimensions.radiusL),
      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_outlined,
            color: AppColors.warning,
            size: 24,
          ),
        ),
        const SizedBox(width: Dimensions.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مستندات تحتاج توقيع',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count مستند تحتاج مراجعة وتوقيع',
                style: TextStyle(fontSize: 13, color: AppColors.gray700),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, RouteNames.documents),
          child: const Text('مراجعة'),
        ),
      ],
    ),
  );
}

Widget _buildUpcomingInstallments(List<InstallmentModel> installments) {
  final displayInstallments = installments.take(3).toList();
  return Column(
    children: displayInstallments.map((installment) {
      final daysUntilDue = installment.dueDate
          .difference(DateTime.now())
          .inDays;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.info.withOpacity(0.08),
              AppColors.info.withOpacity(0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'قسط #${installment.installmentNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$daysUntilDue يوم متبقي',
                    style: TextStyle(color: AppColors.gray600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              '${installment.amount.toStringAsFixed(2)} ر.س',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildConstructionUpdates(List<ConstructionUpdateModel> updates) {
  return SizedBox(
    height: 200,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        return Container(
          width: 300,
          margin: EdgeInsets.only(
            right: index < updates.length - 1 ? Dimensions.spaceM : 0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (update.photos.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusL),
                    topRight: Radius.circular(Dimensions.radiusL),
                  ),
                  child: Image.network(
                    update.photos.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.gray200,
                      child: const Icon(
                        Icons.construction,
                        size: 40,
                        color: AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(update.updateDate ?? DateTime.now()).day}/${(update.updateDate ?? DateTime.now()).month}/${(update.updateDate ?? DateTime.now()).year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                        const Spacer(),
                        if (update.progressPercentage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${update.progressPercentage!.toInt()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
