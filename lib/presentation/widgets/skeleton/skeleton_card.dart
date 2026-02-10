import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

import 'package:shimmer/shimmer.dart';

class SkeletonCard extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.height,
    this.width,
    this.borderRadius = Dimensions.skeletonBorderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.gray300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
