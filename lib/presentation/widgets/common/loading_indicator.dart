import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 32,
        height: size ?? 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
