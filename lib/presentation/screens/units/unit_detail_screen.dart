// lib/presentation/screens/units/unit_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/routes/route_names.dart';

class UnitDetailScreen extends StatelessWidget {
  final UnitModel unit;

  const UnitDetailScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('وحدة ${unit.unitNumber}'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        children: [
          // Status Badge
          _buildStatusBadge(),
          const SizedBox(height: Dimensions.spaceL),

          // Unit Image/Floor Plan
          if (unit.floorPlanUrl != null)
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                image: DecorationImage(
                  image: NetworkImage(unit.floorPlanUrl!),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {},
                ),
              ),
            ),
          const SizedBox(height: Dimensions.spaceL),

          // Unit Details
          _buildDetailsCard(
            'تفاصيل الوحدة',
            [
              _buildDetailRow('رقم الوحدة', unit.unitNumber),
              if (unit.floor != null)
                _buildDetailRow('الطابق', '${unit.floor}'),
              _buildDetailRow('المساحة', '${unit.areaSqm} م²'),
              if (unit.bedrooms != null)
                _buildDetailRow('الغرف', '${unit.bedrooms}'),
              if (unit.bathrooms != null)
                _buildDetailRow('الحمامات', '${unit.bathrooms}'),
              _buildDetailRow('السعر', '${unit.price.toStringAsFixed(2)} ر.س'),
            ],
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Features
          if (unit.features.isNotEmpty) ...[
            _buildDetailsCard(
              'المميزات',
              unit.features.map((f) => _buildFeatureChip(f)).toList(),
            ),
            const SizedBox(height: Dimensions.spaceL),
          ],

          // Reserve/View Button
          if (unit.status == UnitStatus.available)
            PrimaryButton.withIcon(
              text: 'حجز الوحدة',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteNames.selectUnit,
                  arguments: {'unitId': unit.id},
                );
              },
              icon: Icons.home,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (unit.status) {
      case UnitStatus.available:
        color = AppColors.success;
        text = 'متاحة';
        icon = Icons.check_circle;
        break;
      case UnitStatus.reserved:
        color = AppColors.warning;
        text = 'محجوزة';
        icon = Icons.schedule;
        break;
      case UnitStatus.sold:
        color = AppColors.error;
        text = 'مباعة';
        icon = Icons.block;
        break;
      case UnitStatus.blocked:
        color = AppColors.textSecondary;
        text = 'محظورة';
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: Dimensions.spaceL),
          Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceS),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: AppColors.success),
          const SizedBox(width: Dimensions.spaceS),
          Text(feature),
        ],
      ),
    );
  }
}
