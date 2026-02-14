// lib/main.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mmm/core/config/supabase_config.dart';
import 'package:mmm/core/theme/app_theme.dart';
import 'package:mmm/data/repositories/kyc_repository.dart';
import 'package:mmm/presentation/cubits/admin/client_management_cubit.dart';
import 'package:mmm/presentation/cubits/kyc/kyc_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/routes/route_generator.dart';
import 'package:mmm/data/services/supabase_service.dart';

// Repositories
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';
import 'package:mmm/data/repositories/notification_repository.dart';
import 'package:mmm/data/repositories/project_repository.dart';

// Cubits
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/notifications/notifications_cubit.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/project_detail/project_detail_cubit.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';

import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';
import 'package:mmm/presentation/cubits/profile/profile_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';

import 'package:mmm/presentation/cubits/admin/contracts_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/documents_management_cubit.dart';
import 'package:mmm/presentation/cubits/admin/handovers_management_cubit.dart';
import 'package:mmm/core/services/network_service.dart';
import 'package:mmm/core/services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Network Service for connectivity monitoring
  await NetworkService().initialize();

  // Initialize Cache Service for offline support
  await CacheService().initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SharikApp());
}

class SharikApp extends StatelessWidget {
  const SharikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => KycRepository()),

        RepositoryProvider(create: (_) => WalletRepository()),
        RepositoryProvider(create: (_) => ProjectRepository()),
        RepositoryProvider(create: (_) => NotificationRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthCubit(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                ProfileCubit(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => KycCubit(
              // ✅ أضف هذا
              kycRepository: context.read<KycRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                WalletCubit(walletRepository: context.read<WalletRepository>()),
          ),
          BlocProvider(
            create: (context) => ProjectsCubit(
              projectRepository: context.read<ProjectRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ProjectDetailCubit(
              projectRepository: context.read<ProjectRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => NotificationsCubit(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => DashboardCubit(
              walletRepository: context.read<WalletRepository>(),
              projectRepository: context.read<ProjectRepository>(),
            ),
          ),
          BlocProvider(create: (_) => JoinFlowCubit()),

          BlocProvider(create: (_) => DocumentsCubit()),
          BlocProvider(create: (_) => ConstructionCubit()),
          BlocProvider(create: (_) => HandoverCubit()),
          BlocProvider(create: (_) => AdminCubit()),
          BlocProvider(create: (_) => AdminDashboardCubit()), // ✅ Fix
          BlocProvider(create: (_) => ClientManagementCubit()), // ✅ Add

          BlocProvider(create: (_) => ContractsManagementCubit()), // ✅ Add
          BlocProvider(create: (_) => DocumentsManagementCubit()), // ✅ Add
          BlocProvider(create: (_) => HandoversManagementCubit()), // ✅ Add
        ],
        child: MaterialApp(
          title: 'شريك - منصة الاستثمار العقاري',
          debugShowCheckedModeBanner: false,

          supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,

          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: RouteNames.login,

          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
