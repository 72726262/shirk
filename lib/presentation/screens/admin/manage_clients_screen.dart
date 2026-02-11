import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart'; // ✅ تحديث
import 'package:mmm/presentation/screens/admin/client_details_screen.dart'; // ✅ جديد

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({super.key});

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientManagementCubit>().loadClients(); // ✅ تحديث
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<ClientManagementCubit, ClientManagementState>(
        // ✅ تحديث
        listener: (context, state) {
          if (state is ClientManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientManagementLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClientsLoaded) {
            final clients = state.clients;

            if (clients.isEmpty) {
              return const Center(child: Text('لا يوجد عملاء'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ClientManagementCubit>().loadClients();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: client.avatarUrl != null
                            ? NetworkImage(client.avatarUrl!)
                            : null,
                        child: client.avatarUrl == null
                            ? Text(
                                (client.fullName?.isNotEmpty ??
                                        false) // ✅ Fix nullable
                                    ? client.fullName![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        client.fullName ?? 'مستخدم',
                      ), // ✅ Fix nullable
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.email),
                          const SizedBox(height: 4),
                          _buildKycStatusChip(
                            client.kycStatus,
                          ), // ✅ Already KYCStatus
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        // ✅ Navigation إلى ClientDetailsScreen
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                              value: context.read<ClientManagementCubit>(),
                              child: ClientDetailsScreen(client: client),
                            ),
                          ),
                        );

                        // إعادة تحميل القائمة إذا تم تحديث KYC
                        if (result == true) {
                          if (mounted) {
                            context.read<ClientManagementCubit>().loadClients();
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildKycStatusChip(KYCStatus status) {
    // ✅ Fix enum
    Color color;
    String label;

    switch (status) {
      case KYCStatus.approved:
        color = AppColors.success;
        label = 'موافَق عليه';
        break;
      case KYCStatus.underReview:
        color = AppColors.warning;
        label = 'قيد المراجعة';
        break;
      case KYCStatus.rejected:
        color = AppColors.error;
        label = 'مرفوض';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'قيد الانتظار';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
