import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchableClientPicker extends StatefulWidget {
  final List<UserModel>? clients; // Optional: provide list directly
  final String? selectedClientId;
  final Function(UserModel) onClientSelected;

  const SearchableClientPicker({
    super.key,
    this.clients,
    this.selectedClientId,
    required this.onClientSelected,
  });

  @override
  State<SearchableClientPicker> createState() => _SearchableClientPickerState();
}

class _SearchableClientPickerState extends State<SearchableClientPicker> {
  String _searchQuery = '';
  List<UserModel> _allClients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.clients != null) {
      _allClients = widget.clients!;
    } else {
      _loadClients();
    }
  }

  void _loadClients() {
    // If no clients provided, we can fetch them using the Cubit from context
    // This requires the parent to provide ClientManagementCubit
    final cubit = context.read<ClientManagementCubit>();
    if (cubit.state is ClientManagementLoaded) {
      setState(() {
        _allClients = (cubit.state as ClientManagementLoaded).clients;
      });
    } else {
      setState(() => _isLoading = true);
      cubit.loadClients();
      // We'll listen to the stream in build or use a BlocListener/Builder in parent
      // For simplicity in this dialog, we assume parent handles loading if list is passed
      // Or we can use BlocBuilder inside build.
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we rely on context for loading
    if (widget.clients == null) {
      return BlocBuilder<ClientManagementCubit, ClientManagementState>(
        builder: (context, state) {
          if (state is ClientManagementLoading) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is ClientManagementLoaded) {
            _allClients = state.clients;
            return _buildDialogContent();
          }
          return const SizedBox(
            height: 200,
            child: Center(child: Text('فشل تحميل العملاء')),
          );
        },
      );
    }
    return _buildDialogContent();
  }

  Widget _buildDialogContent() {
    final filteredClients = _allClients.where((client) {
      final query = _searchQuery.toLowerCase();
      final nameMatches =
          client.fullName?.toLowerCase().contains(query) ?? false;
      final emailMatches = client.email.toLowerCase().contains(query);
      return nameMatches || emailMatches;
    }).toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            children: [
              Text(
                'اختر العميل',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Dimensions.spaceM),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'بحث باسم العميل أو البريد الإلكتروني...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
              const SizedBox(height: Dimensions.spaceM),
              Expanded(
                child: filteredClients.isEmpty
                    ? const Center(child: Text('لا توجد نتائج'))
                    : ListView.builder(
                        itemCount: filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = filteredClients[index];
                          final isSelected =
                              client.id == widget.selectedClientId;
                          
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor:
                                AppColors.primary.withOpacity(0.05),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              backgroundImage: (client.avatarUrl != null &&
                                      client.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(client.avatarUrl!)
                                  : null,
                              onBackgroundImageError: (client.avatarUrl !=
                                          null &&
                                      client.avatarUrl!.isNotEmpty)
                                  ? (_, __) {}
                                  : null,
                              child: (client.avatarUrl == null ||
                                      client.avatarUrl!.isEmpty)
                                  ? Text(
                                      client.fullName?.isNotEmpty == true
                                          ? client.fullName![0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(client.fullName ?? 'غير محدد'),
                            subtitle: Text(client.email),
                            onTap: () {
                              widget.onClientSelected(client);
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: Dimensions.spaceM),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
