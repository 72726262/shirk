import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/admin/clients_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/payments_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/screens/admin/tabs/projects_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/clients_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/payments_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/construction_updates_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/notifications_composer_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/overview_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
          create: (context) => ClientsManagementCubit(),
        ),
        BlocProvider(
          create: (context) => PaymentsManagementCubit(),
        ),
        BlocProvider(
          create: (context) => AdminNotificationsCubit(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الإدارة'),
          backgroundColor: AppColors.primary,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'الرئيسية'),
              Tab(icon: Icon(Icons.business), text: 'المشاريع'),
              Tab(icon: Icon(Icons.people), text: 'العملاء'),
              Tab(icon: Icon(Icons.payment), text: 'المدفوعات'),
              Tab(icon: Icon(Icons.construction), text: 'التحديثات'),
              Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            OverviewTab(),
            ProjectsManagementTab(),
            ClientsManagementTab(),
            PaymentsManagementTab(),
            ConstructionUpdatesTab(),
            NotificationsComposerTab(),
          ],
        ),
      ),
    );
  }
}
