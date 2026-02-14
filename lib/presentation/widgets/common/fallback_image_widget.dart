import 'package:flutter/material.dart';

class FallbackImageWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData? icon;
  final String? text;
  final Color? color;

  const FallbackImageWidget({
    super.key,
    this.width,
    this.height,
    this.icon = Icons.image_not_supported,
    this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color ?? Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (width ?? 100) * 0.3,
            color: Colors.grey[400],
          ),
          if (text != null) ...[
            const SizedBox(height: 8),
            Text(
              text!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: (width ?? 100) * 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
