import 'package:flutter/material.dart';

class PlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final IconData? icon;
  final String? text;

  const PlaceholderImage({
    super.key,
    this.width,
    this.height,
    this.icon,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.image,
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
            ),
          ],
        ],
      ),
    );
  }
}
