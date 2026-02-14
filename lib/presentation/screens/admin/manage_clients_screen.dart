import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart'; // Keep for KYCStatus if needed
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/client_details_screen.dart';
import 'package:mmm/presentation/screens/admin/widgets/client_table.dart'; // Changed to use table

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

          if (state is ClientManagementLoaded) {
            final clients = state.clients;

            if (clients.isEmpty) {
              return const Center(child: Text('لا يوجد عملاء'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ClientManagementCubit>().loadClients();
              },
              child: ClientTable(clients: clients),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }


}
