import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({super.key});

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadClients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClientsLoaded) {
            final clients = state.clients;

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<AdminCubit>().refreshClients();
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
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(client.fullName ?? '?'),
                      ),
                      title: Text(client.fullName ?? 'مستخدم'),
                      subtitle: Text(client.email ?? ''),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('عرض'),
                          ),
                          const PopupMenuItem(
                            value: 'approve_kyc',
                            child: Text('الموافقة على KYC'),
                          ),
                          const PopupMenuItem(
                            value: 'block',
                            child: Text('حظر'),
                          ),
                        ],
                        onSelected: (value) => _handleClientAction(
                          value.toString(),
                          client.id ?? '',
                        ),
                      ),
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

  void _handleClientAction(String action, String clientId) {
    switch (action) {
      case 'approve_kyc':
        context.read<AdminCubit>().approveKYC(clientId);
        break;
      case 'block':
        context.read<AdminCubit>().blockClient(clientId);
        break;
    }
  }
}
