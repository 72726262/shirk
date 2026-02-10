import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/clients_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/widgets/client_table.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';

class ClientsManagementTab extends StatefulWidget {
  const ClientsManagementTab({super.key});

  @override
  State<ClientsManagementTab> createState() => _ClientsManagementTabState();
}

class _ClientsManagementTabState extends State<ClientsManagementTab> {
  String? _selectedFilter; // null (All), 'pending', 'verified', 'rejected'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<ClientsManagementCubit>().loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(String? status) {
    setState(() => _selectedFilter = status);
    context
        .read<ClientsManagementCubit>()
        .loadClients(kycStatus: status, searchQuery: _searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: Dimensions.spaceL),
          _buildFilters(),
          const SizedBox(height: Dimensions.spaceL),
          Expanded(
            child: BlocBuilder<ClientsManagementCubit, ClientsManagementState>(
              builder: (context, state) {
                if (state is ClientsLoading) {
                  return const SkeletonList();
                }

                if (state is ClientsLoaded) {
                  if (state.clients.isEmpty) {
                    return const Center(child: Text('لا يوجد عملاء'));
                  }
                  return ClientTable(clients: state.clients);
                }

                if (state is ClientsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: Dimensions.spaceM),
                        Text(state.message),
                        ElevatedButton(
                          onPressed: () => _filterClients(_selectedFilter),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'بحث عن عميل (الاسم، البريد الإلكتروني)...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusM),
        ),
      ),
      onChanged: (val) {
        // Debounce logic could be added here
        context
            .read<ClientsManagementCubit>()
            .loadClients(kycStatus: _selectedFilter, searchQuery: val);
      },
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('الكل'),
            selected: _selectedFilter == null,
            onSelected: (_) => _filterClients(null),
          ),
          const SizedBox(width: Dimensions.spaceS),
          FilterChip(
            label: const Text('قيد المراجعة'),
            selected: _selectedFilter == 'pending',
            onSelected: (_) => _filterClients('pending'),
            backgroundColor: AppColors.warning.withOpacity(0.1),
            selectedColor: AppColors.warning.withOpacity(0.3),
          ),
          const SizedBox(width: Dimensions.spaceS),
          FilterChip(
            label: const Text('موثق'),
            selected: _selectedFilter == 'verified',
            onSelected: (_) => _filterClients('verified'),
            backgroundColor: AppColors.success.withOpacity(0.1),
            selectedColor: AppColors.success.withOpacity(0.3),
          ),
          const SizedBox(width: Dimensions.spaceS),
          FilterChip(
            label: const Text('مرفوض'),
            selected: _selectedFilter == 'rejected',
            onSelected: (_) => _filterClients('rejected'),
            backgroundColor: AppColors.error.withOpacity(0.1),
            selectedColor: AppColors.error.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
