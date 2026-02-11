import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/clients_management_cubit.dart';
import 'package:mmm/presentation/screens/admin/screens/client_detail_screen.dart';
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
    context.read<ClientsManagementCubit>().loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(String? status) {
    setState(() => _selectedFilter = status);
    context.read<ClientsManagementCubit>().loadClients(
      kycStatus: status,
      searchQuery: _searchController.text,
    );
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
                    return const Center(
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
                    );
                  }
                  return _buildClientsGrid(state.clients);
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
        context.read<ClientsManagementCubit>().loadClients(
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

  Widget _buildClientsGrid(List<UserModel> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return _ClientCard(client: client);
      },
    );
  }
}

class _ClientCard extends StatelessWidget {
  final UserModel client;

  const _ClientCard({required this.client});

  Color _getKycStatusColor(String? kycStatus) {
    switch (kycStatus) {
      case 'verified':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  String _getKycStatusText(String? kycStatus) {
    switch (kycStatus) {
      case 'verified':
        return 'موثق';
      case 'pending':
        return 'قيد المراجعة';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير مكتمل';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to client details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClientDetailScreen(client: client),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  client.fullName.toString().isNotEmpty
                      ? client.fullName.toString()[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),

              // Client Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Expanded(
                          child: Text(
                            client.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Text(
                          client.phone ?? 'غير متوفر',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getKycStatusColor(client.kycStatus.toString()),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Text(
                      _getKycStatusText(client.kycStatus.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
