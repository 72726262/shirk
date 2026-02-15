import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';

import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/payments_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_notifications_cubit.dart';
import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/subscriptions_management_cubit.dart';
import 'package:mmm/data/repositories/subscription_repository.dart';
import 'package:mmm/presentation/cubits/chat/chat_list_cubit.dart';
import 'package:mmm/data/repositories/chat_repository.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/screens/admin/tabs/projects_tab.dart';
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
import 'package:mmm/presentation/screens/admin/subscriptions_management_screen.dart';
import 'package:mmm/presentation/screens/chat/chat_list_screen.dart';
import 'package:mmm/presentation/screens/admin/widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = const [
    'الرئيسية',
    'المشاريع',
    'العملاء',
    'المدفوعات',
    'التنفيذ',
    'العقود',
    'المستندات',
    'التسليم',
    'الإشعارات',
    'إدارة الاشتراكات', // Index 9
    'الرسائل',         // Index 10
  ];

  final List<Widget> _pages = const [
    OverviewTab(),
    ProjectsTab(),
    ClientsManagementTab(),
    PaymentsManagementTab(),
    ConstructionUpdatesTab(),
    ContractsManagementTab(),
    DocumentsManagementTab(),
    HandoversManagementTab(),
    NotificationsComposerTab(),
    SubscriptionsManagementScreen(), // Index 9
    ChatListScreen(),                // Index 10
  ];

  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().loadDashboard();
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AdminDashboardCubit()..loadDashboard(),
        ),
        BlocProvider(create: (context) => ProjectsCubit()..loadProjects()),
        BlocProvider(
          create: (context) => ClientManagementCubit()..loadClients(),
        ),
        BlocProvider(create: (context) => PaymentsManagementCubit()),
        BlocProvider(create: (context) => AdminNotificationsCubit()),
        BlocProvider(create: (context) => ContractsManagementCubit()),
        BlocProvider(create: (context) => DocumentsManagementCubit()),
        BlocProvider(create: (context) => HandoversManagementCubit()),
        BlocProvider(
          create: (context) => SubscriptionsManagementCubit(
            subscriptionRepository: SubscriptionRepository(),
          )..loadSubscriptions(),
        ),
        BlocProvider(
          create: (context) => ChatListCubit(
            chatRepository: ChatRepository(),
          )..loadChats(),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_pageTitles[_selectedIndex]),
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'إنشاء مستخدم',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'التقارير',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'سجل الأنشطة',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityLogsScreen()),
                );
              },
            ),
          ],
        ),
        drawer: AdminDrawer(
          selectedIndex: _selectedIndex,
          onItemSelected: _navigateToPage,
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_selectedIndex),
            child: _pages[_selectedIndex],
          ),
        ),
      ),
    );
  }
}
