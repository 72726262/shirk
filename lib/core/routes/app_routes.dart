import 'package:flutter/material.dart';
import 'package:mmm/presentation/screens/auth/login_screen.dart';
import 'package:mmm/presentation/screens/auth/register_screen.dart';
import 'package:mmm/presentation/screens/dashboard/client_dashboard.dart';
import 'package:mmm/presentation/screens/projects/projects_list_screen.dart';
import 'package:mmm/presentation/screens/projects/project_detail_screen.dart';
import 'package:mmm/presentation/screens/wallet/wallet_screen.dart';
import 'package:mmm/presentation/screens/notifications/notifications_screen.dart';
import 'package:mmm/presentation/screens/documents/documents_screen.dart';
import 'package:mmm/data/models/project_model.dart';

class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyPhone = '/verify-phone';
  static const String kycVerification = '/kyc-verification';

  // Dashboard Routes
  static const String dashboard = '/dashboard';

  // Projects Routes
  static const String projectsList = '/projects';
  static const String projectDetail = '/projects/detail';

  // Wallet Routes
  static const String wallet = '/wallet';
  static const String addFunds = '/wallet/add-funds';
  static const String withdraw = '/wallet/withdraw';

  // Notifications Routes
  static const String notifications = '/notifications';

  // Documents Routes
  static const String documents = '/documents';

  // Join Project Flow Routes
  static const String selectUnit = '/join/select-unit';
  static const String contractSummary = '/join/contract-summary';
  static const String payment = '/join/payment';
  static const String signature = '/join/signature';
  static const String confirmation = '/join/confirmation';

  // Admin Routes (Future)
  static const String admin = '/admin';
  static const String adminProjects = '/admin/projects';
  static const String adminClients = '/admin/clients';
  static const String adminPayments = '/admin/payments';
  static const String adminReports = '/admin/reports';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      // Dashboard
      case dashboard:
        return MaterialPageRoute(builder: (_) => const ClientDashboard());

      // Projects
      case projectsList:
        return MaterialPageRoute(builder: (_) => const ProjectsListScreen());
      case projectDetail:
        final project = settings.arguments as ProjectModel;
        return MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: project.id),
        );

      // Wallet
      case wallet:
        return MaterialPageRoute(builder: (_) => const WalletScreen());

      // Notifications
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      // Documents
      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());

      // Default (404)
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('غير موجود')),
            body: const Center(
              child: Text('الصفحة غير موجودة'),
            ),
          ),
        );
    }
  }
}
