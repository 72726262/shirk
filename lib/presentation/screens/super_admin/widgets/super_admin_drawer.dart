import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/chat/chat_list_cubit.dart';
import 'package:mmm/presentation/screens/profile/profile_screen.dart';
import 'package:mmm/presentation/widgets/dialogs/logout_dialog.dart';

class SuperAdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SuperAdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: Material(
        color: const Color(0xFF0D0D1A), // Slightly darker than Admin to distinguish
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: BlocBuilder<ChatListCubit, ChatListState>(
                builder: (context, chatState) {
                  int unreadCount = 0;
                  if (chatState is ChatListLoaded) {
                    unreadCount = chatState.totalUnreadCount;
                  }
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: _buildNavigationItems(context, unreadCount),
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        decoration: BoxDecoration(
          color: Colors.indigo.shade900.withOpacity(0.4),
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.indigo.shade300.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated && state.user.avatarUrl != null) {
                    return ClipOval(
                      child: Image.network(
                        state.user.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  }
                  return const Icon(
                    Icons.shield,
                    color: Colors.indigo,
                    size: 30,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      String name = 'Super Admin';
                      if (state is Authenticated) {
                        name = state.user.fullName ?? 'Super Admin';
                      }
                      return Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Super Admin',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationItems(BuildContext context, int unreadCount) {
    final adminItems = [
      _DrawerItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'الرئيسية', index: 0),
      _DrawerItem(icon: Icons.business_outlined, activeIcon: Icons.business, label: 'المشاريع', index: 1),
      _DrawerItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'العملاء', index: 2),
      _DrawerItem(icon: Icons.payment_outlined, activeIcon: Icons.payment, label: 'المدفوعات', index: 3),
      _DrawerItem(icon: Icons.construction_outlined, activeIcon: Icons.construction, label: 'التنفيذ', index: 4),
      _DrawerItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'العقود', index: 5),
      _DrawerItem(icon: Icons.folder_open, activeIcon: Icons.folder, label: 'المستندات', index: 6),
      _DrawerItem(icon: Icons.vpn_key_outlined, activeIcon: Icons.vpn_key, label: 'التسليم', index: 7),
      _DrawerItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'الإشعارات', index: 8),
      _DrawerItem(icon: Icons.bookmark_border, activeIcon: Icons.bookmark, label: 'الحجوزات', index: 9),
      _DrawerItem(
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: 'الرسائل',
        index: 10,
        badge: unreadCount,
      ),
    ];

    // Super Admin exclusive items
    final superAdminItems = [
      _DrawerItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'إدارة المستخدمين', index: 11),
      _DrawerItem(icon: Icons.settings_applications_outlined, activeIcon: Icons.settings_applications, label: 'إعدادات النظام', index: 12),
      _DrawerItem(icon: Icons.security_outlined, activeIcon: Icons.security, label: 'سجلات النظام', index: 13),
      _DrawerItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'التحليلات', index: 14),
    ];

    return [
      ...adminItems.map((item) => _buildDrawerItem(context, item)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Divider(color: Colors.white12),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          'صلاحيات Super Admin',
          style: TextStyle(
            color: Colors.indigo,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      ...superAdminItems.map((item) => _buildDrawerItem(context, item, isSuperAdminSection: true)),
    ];
  }

  Widget _buildDrawerItem(BuildContext context, _DrawerItem item, {bool isSuperAdminSection = false}) {
    final isSelected = selectedIndex == item.index;
    final Color activeColor = isSuperAdminSection ? Colors.indigo.shade300 : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          onItemSelected(item.index);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: activeColor.withOpacity(0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: isSelected ? activeColor : Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
              if (item.badge != null && item.badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => const LogoutDialog(),
              );
              if (confirm == true && context.mounted) {
                context.read<AuthCubit>().signOut();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'الإصدار 1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int? badge;

  _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    this.badge,
  });
}
