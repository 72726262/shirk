import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/super_admin/users_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/screens/admin/tabs/overview_tab.dart'; // Reusing overview
import 'package:mmm/presentation/screens/super_admin/tabs/users_management_tab.dart';
import 'package:mmm/presentation/screens/super_admin/tabs/system_settings_tab.dart';
import 'package:mmm/presentation/screens/super_admin/tabs/audit_logs_tab.dart';
import 'package:mmm/presentation/screens/super_admin/tabs/analytics_tab.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    context.read<AdminDashboardCubit>().loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => UsersManagementCubit(),
        ),
        BlocProvider(
          create: (context) => AdminNotificationsCubit(),
        ),
        // Add specific SuperAdmin cubits here if needed
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم العليا (Super Admin)'),
          backgroundColor: Colors.indigo.shade900, // Distinctive color
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'الرئيسية'),
              Tab(icon: Icon(Icons.manage_accounts), text: 'إدارة المستخدمين'),
              Tab(icon: Icon(Icons.settings_applications), text: 'إعدادات النظام'),
              Tab(icon: Icon(Icons.security), text: 'سجلات النظام'),
              Tab(icon: Icon(Icons.analytics), text: 'التحليلات'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Logout logic
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            OverviewTab(), // Reusing admin overview for now
            UsersManagementTab(),
            SystemSettingsTab(),
            AuditLogsTab(),
            AnalyticsTab(),
          ],
        ),
      ),
    );
  }
}
