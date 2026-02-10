import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:intl/intl.dart';

class UnitCard extends StatelessWidget {
  final UnitModel unit;
  final VoidCallback? onTap;
  final bool isSelected;

  const UnitCard({
    super.key,
    required this.unit,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'ر.س',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: unit.status == UnitStatus.available ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : unit.status == UnitStatus.available
                    ? AppColors.border
                    : AppColors.gray300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Opacity(
          opacity: unit.status == UnitStatus.available ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Unit Number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceS,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray200,
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      ),
                      child: Text(
                        'رقم ${unit.unitNumber}',
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      ),
                      child: Text(
                        unit.status.displayName,
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Unit Type & Floor
                if (unit.unitType != null)
                  Row(
                    children: [
                      Icon(
                        _getUnitIcon(),
                        size: 20,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      Text(
                        unit.unitType!.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                      if (unit.floor != null) ...[
                        const SizedBox(width: Dimensions.spaceM),
                        Text(
                          '• الدور ${unit.floor}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: Dimensions.spaceM),

                // Area & Rooms
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.square_foot,
                      label: '${unit.areaSqm.toStringAsFixed(0)} م²',
                    ),
                    if (unit.bedrooms != null) ...[
                      const SizedBox(width: Dimensions.spaceS),
                      _buildInfoChip(
                        icon: Icons.bed_outlined,
                        label: '${unit.bedrooms}',
                      ),
                    ],
                    if (unit.bathrooms != null) ...[
                      const SizedBox(width: Dimensions.spaceS),
                      _buildInfoChip(
                        icon: Icons.bathroom_outlined,
                        label: '${unit.bathrooms}',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السعر',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        Text(
                          currencyFormatter.format(unit.price),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(Dimensions.spaceS),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceM,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gray600),
          const SizedBox(width: Dimensions.spaceXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (unit.status) {
      case UnitStatus.available:
        return AppColors.success;
      case UnitStatus.reserved:
        return AppColors.warning;
      case UnitStatus.sold:
        return AppColors.error;
      case UnitStatus.blocked:
        return AppColors.gray500;
    }
  }

  IconData _getUnitIcon() {
    switch (unit.unitType) {
      case UnitType.apartment:
        return Icons.apartment;
      case UnitType.villa:
        return Icons.villa;
      case UnitType.shop:
        return Icons.store;
      case UnitType.office:
        return Icons.business;
      case UnitType.land:
        return Icons.landscape;
      case null:
        return Icons.home;
    }
  }
}
