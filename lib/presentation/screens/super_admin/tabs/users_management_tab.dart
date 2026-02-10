import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/super_admin/users_management_cubit.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_list.dart';

class UsersManagementTab extends StatefulWidget {
  const UsersManagementTab({super.key});

  @override
  State<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends State<UsersManagementTab> {
  String? _selectedRole;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Assuming UsersManagementCubit is provided in SuperAdminDashboardScreen
    // Wait, I didn't provide it yet in SuperAdminDashboardScreen! 
    // I should provide it there or here. 
    // Ideally provided by parent. I will update SuperAdminDashboardScreen later.
    // For now, I'll rely on context.read assuming it will be there.
    context.read<UsersManagementCubit>().loadUsers(); 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'بحث عن مستخدم',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    context.read<UsersManagementCubit>().loadUsers(
                      role: _selectedRole,
                      searchQuery: val,
                    );
                  },
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),
              DropdownButton<String>(
                value: _selectedRole,
                hint: const Text('تصفية حسب الدور'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('الكل')),
                  DropdownMenuItem(value: 'client', child: Text('عميل')),
                  DropdownMenuItem(value: 'admin', child: Text('مشرف')),
                  DropdownMenuItem(value: 'super_admin', child: Text('مشرف عام')),
                ],
                onChanged: (val) {
                  setState(() => _selectedRole = val);
                  context.read<UsersManagementCubit>().loadUsers(
                    role: val,
                    searchQuery: _searchController.text,
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<UsersManagementCubit, UsersManagementState>(
            builder: (context, state) {
              if (state is UsersLoading) return const SkeletonList();
              
              if (state is UsersLoaded) {
                return ListView.separated(
                  itemCount: state.users.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text((user.fullName ?? 'U')[0].toUpperCase()),
                      ),
                      title: Text(user.fullName ?? 'مستخدم'),
                      subtitle: Text('${user.email}\nRole: ${user.role}'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (newRole) {
                          _confirmRoleChange(context, user.id, user.role, newRole);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'client', child: Text('Set as Client')),
                          const PopupMenuItem(value: 'admin', child: Text('Set as Admin')),
                          const PopupMenuItem(value: 'super_admin', child: Text('Set as Super Admin')),
                        ],
                        child: const Icon(Icons.edit),
                      ),
                    );
                  },
                );
              }
              
              if (state is UsersError) return Center(child: Text(state.message));
              
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  void _confirmRoleChange(BuildContext context, String userId, String currentRole, String newRole) {
    if (currentRole == newRole) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير الصلاحية'),
        content: Text('هل أنت متأكد من تغيير صلاحية المستخدم إلى $newRole؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              context.read<UsersManagementCubit>().updateUserRole(userId, newRole);
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
