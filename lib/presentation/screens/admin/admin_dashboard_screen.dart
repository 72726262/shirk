import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/admin/clients_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/payments_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/screens/admin/tabs/projects_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/clients_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/payments_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/construction_updates_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/notifications_composer_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/overview_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/contracts_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/documents_management_tab.dart';
import 'package:mmm/presentation/screens/admin/tabs/handovers_management_tab.dart';
import 'package:mmm/presentation/screens/admin/activity_logs_screen.dart';
import 'package:mmm/presentation/screens/admin/reports_screen.dart';
import 'package:mmm/presentation/screens/admin/create_user_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.dashboard), text: 'الرئيسية'),
    Tab(icon: Icon(Icons.business), text: 'المشاريع'),
    Tab(icon: Icon(Icons.people), text: 'العملاء'),
    Tab(icon: Icon(Icons.payment), text: 'المدفوعات'),
    Tab(icon: Icon(Icons.construction), text: 'التنفيذ'),
    Tab(icon: Icon(Icons.description), text: 'العقود'),
    Tab(icon: Icon(Icons.folder), text: 'المستندات'),
    Tab(icon: Icon(Icons.key), text: 'التسليم'),
    Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
  ];

  final List<Widget> _tabViews = const [
    OverviewTab(),
    ProjectsManagementTab(),
    ClientsManagementTab(),
    PaymentsManagementTab(),
    ConstructionUpdatesTab(),
    ContractsManagementTab(),
    DocumentsManagementTab(),
    HandoversManagementTab(),
    NotificationsComposerTab(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
        BlocProvider(
          create: (context) => ContractsManagementCubit(),
        ),
        BlocProvider(
          create: (context) => DocumentsManagementCubit(),
        ),
        BlocProvider(
          create: (context) => HandoversManagementCubit(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
          backgroundColor: AppColors.primary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'إنشاء مستخدم',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateUserScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'التقارير',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'سجل الأنشطة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ActivityLogsScreen(),
                  ),
                );
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.textPrimary),
                      SizedBox(width: 8),
                      Text('الملف الشخصي'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('تسجيل الخروج', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  context.read<AuthCubit>().signOut();
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: _tabs,
            tabAlignment: TabAlignment.start,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabViews,
        ),
      ),
    );
  }
}
