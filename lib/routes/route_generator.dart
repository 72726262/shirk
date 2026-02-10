import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/screens/projects/join_project_flow/signature_screen.dart';
import 'package:mmm/presentation/screens/projects/join_project_flow/signature_screen.dart'
    as new_signature;
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/data/models/installment_model.dart';
import 'package:mmm/data/models/unit_model.dart';

// Auth Screens
import 'package:mmm/presentation/screens/auth/login_screen.dart';
import 'package:mmm/presentation/screens/auth/register_screen.dart';
import 'package:mmm/presentation/screens/auth/verify_phone_screen.dart';
import 'package:mmm/presentation/screens/auth/kyc_verification_screen.dart';

// Dashboard
import 'package:mmm/presentation/screens/dashboard/client_dashboard.dart';
import 'package:mmm/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:mmm/presentation/screens/super_admin/super_admin_dashboard_screen.dart';

// Projects
import 'package:mmm/presentation/screens/projects/projects_list_screen.dart';
import 'package:mmm/presentation/screens/projects/project_detail_screen.dart';

// Join Flow
import 'package:mmm/presentation/screens/projects/join_project_flow/select_unit_screen.dart';
import 'package:mmm/presentation/screens/projects/join_project_flow/contract_summary_screen.dart';
import 'package:mmm/presentation/screens/projects/join_project_flow/payment_screen.dart';

// Wallet
import 'package:mmm/presentation/screens/wallet/wallet_screen.dart';
import 'package:mmm/presentation/screens/wallet/add_funds_screen.dart';
import 'package:mmm/presentation/screens/wallet/withdraw_funds_screen.dart';
import 'package:mmm/presentation/screens/wallet/transaction_history_screen.dart';

// Construction
import 'package:mmm/presentation/screens/construction/construction_tracking_screen.dart';
import 'package:mmm/presentation/screens/construction/construction_updates_screen.dart';

// Subscriptions & Installments
import 'package:mmm/presentation/screens/subscriptions/subscriptions_screen.dart';
import 'package:mmm/presentation/screens/installments/installments_screen.dart';
import 'package:mmm/presentation/screens/installments/installment_detail_screen.dart';

// Units
import 'package:mmm/presentation/screens/units/units_screen.dart';
import 'package:mmm/presentation/screens/units/unit_detail_screen.dart';

// Documents
import 'package:mmm/presentation/screens/documents/documents_screen.dart';
import 'package:mmm/presentation/screens/documents/document_viewer_screen.dart';
import 'package:mmm/presentation/screens/documents/upload_document_screen.dart';

// Handover
import 'package:mmm/presentation/screens/handover/handover_status_screen.dart';
import 'package:mmm/presentation/screens/handover/book_appointment_screen.dart';
import 'package:mmm/presentation/screens/handover/snag_list_screen.dart';
import 'package:mmm/presentation/screens/handover/defects_approval_screen.dart';
import 'package:mmm/presentation/screens/handover/sign_handover_screen.dart';
import 'package:mmm/presentation/screens/handover/handover_confirmation_screen.dart';

// Notifications
import 'package:mmm/presentation/screens/notifications/notifications_screen.dart';
import 'package:mmm/presentation/screens/notifications/notification_detail_screen.dart';

// Profile
import 'package:mmm/presentation/screens/profile/profile_screen.dart';
import 'package:mmm/presentation/screens/profile/edit_profile_screen.dart';
import 'package:mmm/presentation/screens/profile/settings_screen.dart';

// Admin
import 'package:mmm/presentation/screens/admin/manage_clients_screen.dart';
import 'package:mmm/presentation/screens/admin/manage_projects_screen.dart';
import 'package:mmm/presentation/screens/admin/manage_payments_screen.dart';
import 'package:mmm/presentation/screens/admin/reports_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Auth Routes
      case RouteNames.login:
        return _fadeRoute(const LoginScreen());

      case RouteNames.register:
        return _fadeRoute(const RegisterScreen());

      case RouteNames.verifyPhone:
        if (args is String) {
          return _slideRoute(VerifyPhoneScreen(phoneNumber: args));
        }
        return _errorRoute('رقم الهاتف مطلوب');

      case RouteNames.kycVerification:
        return _slideRoute(const KYCVerificationScreen());

      // Dashboard
      case RouteNames.dashboard:
        // Get current auth state to determine which dashboard to show
        return MaterialPageRoute(
          builder: (context) {
            try {
              final authCubit = BlocProvider.of<AuthCubit>(context);
              final authState = authCubit.state;
              
              if (authState is Authenticated) {
                // Route based on user role
                switch (authState.user.role) {
                  case 'super_admin':
                    return const SuperAdminDashboardScreen();
                  case 'admin':
                    return const AdminDashboardScreen();
                  case 'client':
                  default:
                    return const ClientDashboard();
                }
              }
              // If not authenticated, redirect to login
              return const LoginScreen();
            } catch (e) {
              // Fallback to client dashboard if there's any error
              return const ClientDashboard();
            }
          },
        );

      case RouteNames.clientDashboard:
        return _fadeRoute(const ClientDashboard());

      case RouteNames.adminDashboard:
        return _fadeRoute(const AdminDashboardScreen());

      // Projects
      case RouteNames.projectsList:
        return _fadeRoute(const ProjectsListScreen());

      case RouteNames.projectDetail:
        if (args is String) {
          return _slideRoute(ProjectDetailScreen(projectId: args));
        }
        return _errorRoute('معرف المشروع مطلوب');

      // Join Flow
      case RouteNames.selectUnit:
        if (args is ProjectModel) {
          return _slideRoute(SelectUnitScreen(projectId: args.id));
        }
        return _errorRoute('المشروع مطلوب');

      case RouteNames.contractSummary:
        if (args is Map) {
          return _slideRoute(
            ContractSummaryScreen(
              projectId: args['projectId'],
              unitId: args['unitId'],
            ),
          );
        }
        return _errorRoute('بيانات العقد مطلوبة');

      case RouteNames.payment:
        if (args is Map) {
          return _slideRoute(
            PaymentScreen(
              subscriptionId: args['subscriptionId'],
              amount: args['amount'] ?? 0.0,
            ),
          );
        }
        return _errorRoute('بيانات الدفع مطلوبة');

      case RouteNames.signature:
        if (args is Map) {
          return _slideRoute(
            new_signature.SignatureScreen(
              // الملف الجديد
              subscriptionId: args['subscriptionId'],
            ),
          );
        }
        return _errorRoute('بيانات التوقيع مطلوبة');

      // Wallet
      case RouteNames.wallet:
        return _fadeRoute(const WalletScreen());

      case RouteNames.addFunds:
        return _slideRoute(const AddFundsScreen());

      case RouteNames.withdrawFunds:
        return _slideRoute(const WithdrawFundsScreen());

      case RouteNames.transactionHistory:
        return _slideRoute(const TransactionHistoryScreen());

      // Subscriptions & Installments
      case RouteNames.subscriptions:
        return _fadeRoute(const SubscriptionsScreen());

      case RouteNames.installments:
        if (args is String?) {
          return _fadeRoute(InstallmentsScreen(subscriptionId: args));
        }
        return _fadeRoute(const InstallmentsScreen());

      case RouteNames.installmentDetail:
        if (args is InstallmentModel) {
          return _slideRoute(InstallmentDetailScreen(installment: args));
        }
        return _errorRoute('تفاصيل القسط مطلوبة');

      // Units
      case RouteNames.units:
        if (args is String) {
          return _fadeRoute(UnitsScreen(projectId: args));
        }
        return _errorRoute('معرف المشروع مطلوب');

      case RouteNames.unitDetail:
        if (args is UnitModel) {
          return _slideRoute(UnitDetailScreen(unit: args));
        }
        return _errorRoute('تفاصيل الوحدة مطلوبة');

      // Construction
      case RouteNames.constructionTracking:
        if (args is String) {
          return _fadeRoute(ConstructionTrackingScreen(projectId: args));
        }
        return _errorRoute('معرف المشروع مطلوب');

      case RouteNames.constructionUpdates:
        if (args is String) {
          return _fadeRoute(ConstructionUpdatesScreen(projectId: args));
        }
        return _errorRoute('معرف المشروع مطلوب');

      // Documents
      case RouteNames.documents:
        return _fadeRoute(const DocumentsScreen());

      case RouteNames.documentViewer:
        if (args is Map && args['documentId'] != null) {
          return _slideRoute(
            DocumentViewerScreen(documentId: args['documentId']),
          );
        }
        return _errorRoute('المستند مطلوب');

      case RouteNames.uploadDocument:
        return _slideRoute(const UploadDocumentScreen());

      // Handover
      case RouteNames.handoverStatus:
        if (args is String) {
          return _fadeRoute(HandoverStatusScreen(unitId: args));
        }
        return _errorRoute('Unit ID required');

      case RouteNames.bookAppointment:
        if (args is String) {
          return _slideRoute(BookAppointmentScreen(unitId: args));
        }
        return _errorRoute('Unit ID required');

      case RouteNames.snagList:
        if (args is String) {
          return _slideRoute(SnagListScreen(unitId: args));
        }
        return _errorRoute('Unit ID required');

      case RouteNames.defectsApproval:
        if (args is Map) {
          return _slideRoute(DefectsApprovalScreen(unitId: args['unitId']));
        }
        return _errorRoute('Project ID and Unit ID required');

      case RouteNames.signHandover:
        if (args is String) {
          return _slideRoute(SignHandoverScreen(unitId: args));
        }
        return _errorRoute('Unit ID required');

      case RouteNames.handoverConfirmation:
        if (args is String) {
          return _fadeRoute(HandoverConfirmationScreen(unitId: args));
        }
        return _errorRoute('Unit ID required');

      // Notifications
      case RouteNames.notifications:
        return _fadeRoute(const NotificationsScreen());

      case RouteNames.notificationDetail:
        if (args is Map && args['notificationId'] != null) {
          return _slideRoute(
            NotificationDetailScreen(notificationId: args['notificationId']),
          );
        }
        return _errorRoute('الإشعار مطلوب');

      // Profile
      case RouteNames.profile:
        return _fadeRoute(const ProfileScreen());

      case RouteNames.editProfile:
        return _slideRoute(const EditProfileScreen());

      case RouteNames.settings:
        return _slideRoute(const SettingsScreen());

      // Admin
      case RouteNames.manageClients:
        return _fadeRoute(const ManageClientsScreen());

      case RouteNames.manageProjects:
        return _fadeRoute(const ManageProjectsScreen());

      case RouteNames.managePayments:
        return _fadeRoute(const ManagePaymentsScreen());

      case RouteNames.reports:
        return _fadeRoute(const ReportsScreen());

      default:
        return _errorRoute('الصفحة غير موجودة');
    }
  }

  // Fade transition
  static Route _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide transition
  static Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Error route
  static Route _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(
          child: Text(message, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
