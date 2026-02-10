import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';

/// Banner shown when device is offline
class NoNetworkBanner extends StatelessWidget {
  const NoNetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.error,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.wifi_off, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'لا يوجد اتصال بالإنترنت',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
