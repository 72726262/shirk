import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/screens/projects/project_location_map_screen.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/routes/route_names.dart';

class UnitDetailBookingScreen extends StatelessWidget {
  final ProjectModel project;
  final UnitModel unit;

  const UnitDetailBookingScreen({
    super.key,
    required this.project,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تفاصيل الوحدة #${unit.unitNumber}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Project Header Image (Placeholder or Actual)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                image: project.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(project.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: project.imageUrl == null
                  ? const Center(
                      child: Icon(Icons.apartment, size: 64, color: AppColors.primary),
                    )
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Name & Developer
                  Text(
                    project.nameAr,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'المطور: ${project.developer}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: Dimensions.spaceXL),

                  // Unit Details Grid
                  const Text(
                    'تفاصيل الوحدة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  _buildDetailsGrid(),
                  
                  const Divider(height: Dimensions.spaceXL),

                  // Location & Visit
                  const Text(
                    'الموقع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          project.locationName ?? 'موقع غير محدد',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (project.locationLat != null && project.locationLng != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectLocationMapScreen(
                                projectName: project.nameAr,
                                projectLocation: LatLng(project.locationLat!, project.locationLng!),
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('إحداثيات الموقع غير متوفرة')),
                          );
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('زيارة الموقع على الخريطة'),
                    ),
                  ),

                  const Divider(height: Dimensions.spaceXL),

                  // Policies
                  const Text(
                    'سياسة الحجز والشروط',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  const Text(
                    '• يجب دفع مبلغ جدية الحجز خلال 24 ساعة.\n'
                    '• المبلغ غير مسترد في حالة الإلغاء بعد توقيع العقد.\n'
                    '• يرجى مراجعة تفاصيل العقد بدقة قبل الدفع.',
                    style: TextStyle(height: 1.5, color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: Dimensions.spaceXXL),

                  // Book Button
                  PrimaryButton(
                    text: 'متابعة الحجز',
                    onPressed: () {
                      // Update Cubit with Project ID and Unit
                      context.read<JoinFlowCubit>().initBooking(project.id, unit);
                      
                      // Navigate to Contract Summary
                      Navigator.pushNamed(
                        context,
                        RouteNames.contractSummary,
                        arguments: {'projectId': project.id, 'unitId': unit.id},
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      mainAxisSpacing: Dimensions.spaceM,
      crossAxisSpacing: Dimensions.spaceM,
      children: [
        _buildInfoCard(Icons.confirmation_number, 'رقم الوحدة', unit.unitNumber),
        _buildInfoCard(Icons.layers, 'الدور', unit.floor?.toString() ?? '-'),
        _buildInfoCard(Icons.aspect_ratio, 'المساحة', '${unit.areaSqm} م²'),
        _buildInfoCard(Icons.attach_money, 'السعر', '${unit.price} ر.س'),
        _buildInfoCard(Icons.bed, 'غرف النوم', unit.bedrooms?.toString() ?? '-'),
        _buildInfoCard(Icons.bathtub, 'دورات المياه', unit.bathrooms?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
