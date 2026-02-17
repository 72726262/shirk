// lib/main.dart
import 'package:device_preview/device_preview.dart';
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
import 'package:mmm/data/repositories/chat_repository.dart';
import 'package:mmm/data/repositories/payments_repository.dart';

// Cubits
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/cubits/chat/chat_list_cubit.dart';
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
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/data/repositories/units_repository.dart';
import 'package:mmm/core/services/network_service.dart';
import 'package:mmm/core/services/cache_service.dart';

import 'package:mmm/presentation/widgets/chat/global_message_listener.dart';
import 'package:mmm/core/utils/global_route_observer.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  runApp(DevicePreview(enabled: true, builder: (context) => const SharikApp()));
  // runApp(const SharikApp());
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
        RepositoryProvider(create: (_) => ChatRepository()),
        RepositoryProvider(create: (_) => UnitsRepository()),
        RepositoryProvider(
          create: (_) => PaymentsRepository(SupabaseService.instance.client),
        ),
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

          BlocProvider(
            create: (context) => UnitsManagementCubit(
              unitsRepository: context.read<UnitsRepository>(),
            ),
          ),

          BlocProvider(create: (_) => ContractsManagementCubit()), // ✅ Add
          BlocProvider(create: (_) => DocumentsManagementCubit()), // ✅ Add
          BlocProvider(create: (_) => HandoversManagementCubit()), // ✅ Add

          BlocProvider(
            create: (context) =>
                ChatListCubit(chatRepository: context.read<ChatRepository>())
                  ..loadChats(),
          ),
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

          locale: const Locale('ar', 'SA'), // Force Arabic RTL

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,

          navigatorKey: navigatorKey,
          navigatorObservers: [GlobalRouteObserver()],
          onGenerateRoute: RouteGenerator.generateRoute,
          initialRoute: RouteNames.splash,

          builder: (context, child) {
            return BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Unauthenticated) {
                  // Schedule navigation after the current frame to avoid layout errors
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      RouteNames.login,
                      (route) => false,
                    );
                  });
                }
              },
              child: GlobalMessageListener(
                navigatorKey: navigatorKey,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}

double responsiveWidth({
  required BuildContext context,
  required double fontSize,
}) {
  double screenWidth = MediaQuery.of(context).size.width;
  double font;
  if (screenWidth < 600) {
    font = (screenWidth / 400) * fontSize;
    return font.clamp(fontSize * 0.8, fontSize * 1.2);
  } else if (screenWidth < 900) {
    font = (screenWidth / 700) * fontSize;
    return font.clamp(fontSize * 0.8, fontSize * 1.2);
  } else {
    font = (screenWidth / 1000) * fontSize;
    return font.clamp(fontSize * 0.8, fontSize * 1.2);
  }
}

double responsiveHeight({
  required BuildContext context,
  required double height,
}) {
  double screenWidth = MediaQuery.of(context).size.width;
  double calculatedHeight;

  if (screenWidth < 600) {
    calculatedHeight = (screenWidth / 400) * height;
    return calculatedHeight.clamp(height * 0.8, height * 1.2);
  } else if (screenWidth < 900) {
    calculatedHeight = (screenWidth / 700) * height;
    return calculatedHeight.clamp(height * 0.8, height * 1.2);
  } else {
    calculatedHeight = (screenWidth / 1000) * height;
    return calculatedHeight.clamp(height * 0.8, height * 1.2);
  }
}
