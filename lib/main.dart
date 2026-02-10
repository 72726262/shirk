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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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

  const bool isDevicePreviewEnabled = true;

  if (isDevicePreviewEnabled) {
    runApp(
      DevicePreview(enabled: true, builder: (context) => const SharikApp()),
    );
  } else {
    runApp(const SharikApp());
  }
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
          BlocProvider(
            create: (context) => AdminDashboardCubit(
              projectRepository: context.read<ProjectRepository>(),
              walletRepository: context.read<WalletRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'شريك - منصة الاستثمار العقاري',
          debugShowCheckedModeBanner: false,

          // DevicePreview locale
          locale: DevicePreview.locale(context),

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
            final preview = DevicePreview.appBuilder(context, child);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: preview ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
