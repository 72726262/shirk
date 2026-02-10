// lib/presentation/screens/units/units_screen.dart
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class UnitsScreen extends StatelessWidget {
  final String projectId;
  
  const UnitsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الوحدات المتاحة'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Text('قائمة الوحدات قيد الإنشاء'),
      ),
    );
  }
}
