import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart' as mmm; // using alias to match usage or simply direct import if preferred
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart'; // Direct import for state check
import 'package:mmm/data/repositories/admin_repository.dart';
import 'package:mmm/data/repositories/chat_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/presentation/widgets/skeleton_loaders.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      // Fetch users based on current user role
      final authState = context.read<AuthCubit>().state;
      String? userRole;
      if (authState is Authenticated) {
        userRole = authState.user.role;
      }

      // Start building query
      var query = Supabase.instance.client
          .from('profiles')
          .select()
          .neq('id', _currentUserId);

      // If client, only show admins
      if (userRole == 'client') {
        query = query.or('role.eq.admin,role.eq.super_admin');
      }
      
      // Apply ordering last
      final response = await query.order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(response);
          _filteredUsers = _allUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المستخدمين: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _allUsers;
      });
      return;
    }

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString().toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      }).toList();
    });
  }

  Future<void> _startChat(String userId, String userName) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Check if chat exists or create new
      final chatId = await _chatRepository.createOrGetChat(userId);

      if (mounted) {
        // Close loading
        Navigator.pop(context);

        // Navigate to chat room
        Navigator.pushReplacementNamed(
          context,
          RouteNames.chatRoom,
          arguments: {'chatId': chatId, 'otherUserId': userId},
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل بدء المحادثة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'super_admin':
        return 'مدير عام';
      case 'client':
        return 'عميل';
      default:
        return 'مستخدم';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'client':
        return Icons.person;
      default:
        return Icons.account_circle;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
      case 'super_admin':
        return AppColors.primary;
      case 'client':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بدء محادثة جديدة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد أو الهاتف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),

          // Results count
          if (!_isLoading && _filteredUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'عدد النتائج: ${_filteredUsers.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),

          const Divider(height: 1),

          // Users List
          Expanded(
            child: _isLoading
                ? const UserListSkeleton(itemCount: 8)
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'لا يوجد مستخدمين متاحين'
                              : 'لا توجد نتائج للبحث',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            child: const Text('مسح البحث'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final name = user['full_name'] ?? 'مستخدم';
                      final email = user['email'] ?? '';
                      final phone = user['phone'];
                      final role = user['role'] ?? 'client';
                      final avatarUrl = user['avatar_url'];

                      return ListTile(
                        onTap: () => _startChat(user['id'], name),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _getRoleColor(
                                role,
                              ).withOpacity(0.1),
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Icon(
                                      _getRoleIcon(role),
                                      color: _getRoleColor(role),
                                      size: 28,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRoleLabel(role),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (phone != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
