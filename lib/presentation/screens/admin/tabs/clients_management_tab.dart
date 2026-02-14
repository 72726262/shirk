import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/widgets/client_card.dart';

import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';

class ClientsManagementTab extends StatefulWidget {
  const ClientsManagementTab({super.key});

  @override
  State<ClientsManagementTab> createState() => _ClientsManagementTabState();
}

class _ClientsManagementTabState extends State<ClientsManagementTab> {
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientManagementCubit>().loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(String? status) {
    setState(() => _selectedFilter = status);
    context.read<ClientManagementCubit>().loadClients(
      kycStatus: status,
      searchQuery: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ClientManagementCubit>().loadClients(
              kycStatus: _selectedFilter,
              searchQuery: _searchController.text,
            );
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: Dimensions.spaceL),
                _buildFilters(),
                const SizedBox(height: Dimensions.spaceL),
              ]),
            ),
          ),
          BlocBuilder<ClientManagementCubit, ClientManagementState>(
            builder: (context, state) {
              if (state is ClientManagementLoading) {
                return const SliverFillRemaining(
                  child: SkeletonList(),
                );
              }

              if (state is ClientManagementLoaded) {
                if (state.clients.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: Dimensions.spaceL),
                          Text('لا يوجد عملاء'),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.spaceL,
                    0,
                    Dimensions.spaceL,
                    Dimensions.spaceL,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: Dimensions.spaceM,
                      mainAxisSpacing: Dimensions.spaceM,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ClientCard(client: state.clients[index]);
                      },
                      childCount: state.clients.length,
                    ),
                  ),
                );
              }

              if (state is ClientManagementError) {
                return SliverFillRemaining(
                  child: Center(
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
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
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
        context.read<ClientManagementCubit>().loadClients(
          kycStatus: _selectedFilter,
          searchQuery: val,
        );
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
