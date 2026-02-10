import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/config/supabase_config.dart';
import 'package:mmm/core/theme/app_theme.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/routes/route_generator.dart';
import 'package:mmm/data/services/supabase_service.dart';

// Repositories
import 'package:mmm/data/repositories/auth_repository.dart';
import 'package:mmm/data/repositories/wallet_repository.dart';
import 'package:mmm/data/repositories/notification_repository.dart';
import 'package:mmm/data/repositories/project_repository.dart';

// Cubits
// Core Cubits
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/wallet/wallet_cubit.dart';
import 'package:mmm/presentation/cubits/notifications/notifications_cubit.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';

// Feature Cubits
import 'package:mmm/presentation/cubits/kyc/kyc_cubit.dart';
import 'package:mmm/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/project_detail/project_detail_cubit.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/cubits/documents/documents_cubit.dart';

// Advanced Feature Cubits
import 'package:mmm/presentation/cubits/construction/construction_cubit.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';

// Profile & Admin Cubits
import 'package:mmm/presentation/cubits/profile/profile_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Lock to portrait mode
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
        RepositoryProvider<AuthRepository>(create: (context) => AuthRepository()),
        RepositoryProvider<WalletRepository>(create: (context) => WalletRepository()),
        RepositoryProvider<ProjectRepository>(create: (context) => ProjectRepository()),
        RepositoryProvider<NotificationRepository>(create: (context) => NotificationRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          // Core
          BlocProvider(create: (context) => AuthCubit(authRepository: context.read<AuthRepository>())),
          BlocProvider(create: (context) => WalletCubit(walletRepository: context.read<WalletRepository>())),
          BlocProvider(create: (context) => NotificationsCubit(notificationRepository: context.read<NotificationRepository>())),
          BlocProvider(create: (context) => ProjectsCubit(projectRepository: context.read<ProjectRepository>())),
          
          // Features
          BlocProvider(create: (context) => KYCCubit()),
          BlocProvider(create: (context) => DashboardCubit(
            walletRepository: context.read<WalletRepository>(),
            projectRepository: context.read<ProjectRepository>(),
          )),
          BlocProvider(create: (context) => ProjectDetailCubit(
            projectRepository: context.read<ProjectRepository>(),
          )),
          BlocProvider(create: (context) => JoinFlowCubit()),
          BlocProvider(create: (context) => DocumentsCubit()),
          BlocProvider(create: (context) => ConstructionCubit()),
          BlocProvider(create: (context) => HandoverCubit()),
          
          // Admin & Profile
          BlocProvider(create: (context) => ProfileCubit()),
          BlocProvider(create: (context) => AdminCubit()),
          BlocProvider(create: (context) => AdminDashboardCubit(
            projectRepository: context.read<ProjectRepository>(),
            walletRepository: context.read<WalletRepository>(),
          )),
        ],
        child: MaterialApp(
          title: 'شريك - منصة الاستثمار العقاري',
          debugShowCheckedModeBanner: false,
          
          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          
          // Localization - RTL Arabic
          locale: const Locale('ar', 'SA'),
          supportedLocales: const [
            Locale('ar', 'SA'),
            Locale('en', 'US'),
          ],
          
          // Routing
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: RouteNames.splash, // Updated to splash or login
          
          // Builder for global error handling
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

