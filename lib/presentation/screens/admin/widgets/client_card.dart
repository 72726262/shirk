import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/client_details_screen.dart';

class ClientCard extends StatelessWidget {
  final UserModel client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: InkWell(
        onTap: () => _showClientDetails(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: client.avatarUrl != null
                    ? NetworkImage(client.avatarUrl!)
                    : null,
                child: client.avatarUrl == null
                    ? Text(
                        (client.fullName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: Dimensions.spaceM),

              // Name
              Text(
                client.fullName ?? 'مستخدم غير معروف',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Dimensions.spaceXS),

              // Email
              Text(
                client.email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Dimensions.spaceM),

              // Status Chip
              _buildStatusChip(client.kycStatus),
              
              const Spacer(),
              
              // Action Button (View Details)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showClientDetails(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  ),
                  child: const Text('عرض التفاصيل'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(KYCStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case KYCStatus.approved:
        color = AppColors.success;
        label = 'موثق';
        icon = Icons.check_circle;
        break;
      case KYCStatus.underReview:
        color = AppColors.warning;
        label = 'قيد المراجعة';
        icon = Icons.access_time_filled;
        break;
      case KYCStatus.rejected:
        color = AppColors.error;
        label = 'مرفوض';
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.textSecondary;
        label = 'غير مكتمل';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<ClientManagementCubit>(),
          child: ClientDetailsScreen(client: client),
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.read<ClientManagementCubit>().loadClients();
    }
  }
}
